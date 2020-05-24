// Shopify setup w/Lambdas reference: https://alternatelabs.co/blog/creating-a-shopify-app-using-serverless-tech
// Shopify OAuth docs: https://shopify.dev/tutorials/authenticate-with-oauth#step-1-get-the-clients-credentials
open Lambda;
open LambdaUtils;
open Belt;
open ShopQueries;
open Js.Promise;

let query = (q, ast) =>
  GraphQL.(
    Client.instance.query
    ->Obj.magic({"query": ast, "variables": q##variables})
    |> then_(response => {
         let apolloData = toApolloResult(response);
         let result =
           Belt.Option.map(
             apolloData##data |> Js.Nullable.toOption,
             q##parse,
           );
         resolve(result);
       })
  );

let getUser = id => {
  let q = GetShop.make(~id, ());
  let videoAST = ApolloClient.gql(. q##query);
  query(q, videoAST);
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
        if (verified.isInstalled) {
          getUser(verified.shop)
          ->FutureJs.fromPromise(error => {
              error->Sentry.capturePromiseException;
              error->Js.log;
              error;
            })
          ->Future.flatMap(res => {
              switch (res) {
              | Ok(Some(data)) =>
                switch (data##shops->Array.get(0)) {
                | None =>
                  Future.make(r =>
                    "Failed to fetch user after verification"->Error->r
                  )
                | Some(user) => Future.make(r => user->Ok->r)
                }
              | Ok(None)
              | Error(_) =>
                Future.make(r =>
                  "Failed to fetch user after verification"->Error->r
                )
              }
            })
          ->Future.get(res =>
              switch (res) {
              | Ok(data) =>
                let accessToken = data##accessToken;
                let {shop} = verified;
                resolve(. {
                  statusCode: 302,
                  body: Js.Nullable.null,
                  headers:
                    headersBase(
                      ~location=
                        verified.env.appUrl
                        ++ {j|?accessToken=$accessToken&shop=$shop&apiKey=$apiKey|j},
                      (),
                    ),
                });
              | Error(message) =>
                SS.Sentry.Node.captureMessage(message);
                resolve(. {
                  statusCode: 500,
                  body: "Failed to fetch shop data"->Js.Nullable.return,
                  headers,
                });
              }
            );
        } else {
          let {shop} = verified;
          let redirectUri =
            verified.params.redirect
            ->Js.Nullable.toOption
            ->Belt.Option.getWithDefault(verified.env.redirect);
          let nonce = Crypto.randomBytes(16)->Crypto.toString("base64");
          resolve(. {
            statusCode: 302,
            body: Js.Nullable.null,
            headers:
              headersBase(
                ~location=
                  {j|https://$shop/admin/oauth/authorize?client_id=$apiKey&scope=$scopes&redirect_uri=$redirectUri&state=$nonce|j},
                (),
              ),
          });
        }
      }
    })
    |> catch(error => {
         error->SS.Sentry.Node.capturePromiseException;
         resolve({
           statusCode: 500,
           body: error->Obj.magic->Js.Nullable.return,
           headers,
         });
       });
  };