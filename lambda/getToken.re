open Lambda;
open LambdaUtils;
open SharedUtils;
open Types;
open Belt;
open ShopQueries;
open Js.Promise;

[%raw "require('isomorphic-fetch')"];

type queryParamsForCheck = {
  .
  "shop": string,
  "code": string,
  "state": string,
  "timestamp": string,
};

[@decco]
type shopifyToken = {
  access_token: string,
  scope: string,
};

[@decco]
type accessTokenPayload = {
  client_id: string,
  client_secret: string,
  code: string,
};

[@bs.module "querystring"] external qsStringify: 'a => string = "stringify";

let mutation = (q, ast) =>
  GraphQL.(
    Client.instance.mutate
    ->Obj.magic({"mutation": ast, "variables": q##variables})
    |> Js.Promise.then_(response => {
         let apolloData = toApolloResult(response);
         let result =
           Belt.Option.map(
             apolloData##data |> Js.Nullable.toOption,
             q##parse,
           );
         Js.Promise.resolve(result);
       })
  );

let createShop = (id, accessToken) => {
  let q = CreateShop.make(~id, ~accessToken, ());
  let videoAST = ApolloClient.gql(. q##query);
  mutation(q, videoAST);
};

type requestHeaders;

let handler: handler(event(requestHeaders)) =
  (event, _context) => {
    make((~resolve, ~reject as _) => {
      switch (event.queryStringParameters->Verify.request) {
      | Error(message) =>
        resolve(. {
          statusCode: 400,
          body: message->Js.Nullable.return,
          headers,
        })
      | Ok(verified) =>
        switch (verified.params.code->Js.Nullable.toOption) {
        | Some(code) =>
          let shop = verified.shop;
          Fetch.fetchWithInit(
            {j|https://$shop/admin/oauth/access_token|j},
            Fetch.RequestInit.make(
              ~method_=Post,
              ~body=
                {
                  client_id: verified.env.apiKey,
                  client_secret: verified.env.apiSecret,
                  code,
                }
                ->accessTokenPayload_encode
                ->Js.Json.stringify
                ->Fetch.BodyInit.make,
              ~headers=
                Fetch.HeadersInit.make({
                  "Accept": "application/json",
                  "Content-Type": "application/json",
                }),
              (),
            ),
          )
          ->FutureJs.fromPromise(error => {
              error->Sentry.capturePromiseException;
              error->Js.log;
              error;
            })
          ->Future.mapError(error => {
              let errorString: string = error->Obj.magic;
              {j|Failure to retrieve access token with error: $errorString|j};
            })
          ->Future.flatMapOk(response =>
              response
              ->Fetch.Response.json
              ->FutureJs.fromPromise(error => {
                  error->Sentry.capturePromiseException;
                  error->Js.log;
                  error;
                })
              ->Future.mapError(error => error->Obj.magic)
            )
          ->Future.flatMapOk(json =>
              switch (json->shopifyToken_decode) {
              | Ok(token) => Future.make(r => token->Ok->r)
              | Error({path, message, value}) =>
                let value = value->Js.Json.stringify;
                let json = json->Js.Json.stringify;
                Future.make(r =>
                  {j|
                      ---Shopify Token Decode Error---

                      Path: $path

                      Message: $message

                      Value: $value

                      Json Source: $json
                    |j}
                  ->Error
                  ->r
                );
              }
            )
          ->Future.flatMapOk(({access_token, scope}) =>
              if (scope == verified.env.scopes) {
                createShop(shop, access_token)
                ->FutureJs.fromPromise(error => {
                    error->Sentry.capturePromiseException;
                    error->Js.log;
                    error;
                  })
                ->Future.mapError(error => {
                    let error: string = error->Obj.magic;
                    {j|Failed to store shop: $error|j};
                  })
                ->Future.mapOk(_ =>
                    (
                      {
                        shop,
                        accessToken: access_token,
                        apiKey: verified.env.apiKey,
                      }: Types.shopifyAuthed
                    )
                  );
              } else {
                Future.make(r =>
                  {j|Scope validation failed: scopes from token ($scope) does not match rhe requested scopes ($scopes)|j}
                  ->Error
                  ->r
                );
              }
            )
          ->Future.get(res =>
              switch (res) {
              | Error(message) =>
                resolve(. {
                  statusCode: 400,
                  body: message->Js.Nullable.return,
                  headers,
                })

              | Ok({accessToken, shop, apiKey}) =>
                resolve(. {
                  statusCode: 302,
                  headers:
                    headersBase(
                      ~location=
                        appUrl->Belt.Option.getWithDefault("")
                        ++ {j|?accessToken=$accessToken&shop=$shop&apiKey=$apiKey|j},
                      (),
                    ),
                  body: Js.Nullable.null,
                })
              }
            );
        | None =>
          resolve(. {
            statusCode: 400,
            body:
              "`code` query parameter was not provided. Get token request cannot be completed."
              ->Js.Nullable.return,
            headers,
          })
        }
      }
    })
    |> catch(error =>
         resolve({
           statusCode: 500,
           headers,
           body: error->Obj.magic->Js.Nullable.return,
         })
       );
  };