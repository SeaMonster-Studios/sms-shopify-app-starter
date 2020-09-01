open Belt;
open Lambda;
open LambdaUtils;

type requestHeaders = {. "Shopify-Access-Token": Js.Nullable.t(string)};

let handler: handler(event(requestHeaders)) =
  (event, _context) => {
    Js.Promise.(
      make((~resolve, ~reject as _) => {
        switch (event.headers##"Shopify-Access-Token"->Js.Nullable.toOption) {
        | Some(accessToken) =>
          resolve(. {
            statusCode: 200,
            body:
              {
                "X-Hasura-Admin-Secret":
                  hasuraAdminSecret->Option.getWithDefault(""),
                "X-Hasura-Role": "shop",
                "X-Hasura-User-Id": accessToken,
              }
              ->Obj.magic
              ->Js.Json.stringify
              ->Js.Nullable.return,
            headers,
          })
        | None =>
          resolve(. {statusCode: 400, body: Js.Nullable.null, headers})
        }
      })
      |> catch(error =>
           Js.Promise.resolve({
             statusCode: 500,
             body: error->Obj.magic->Js.Nullable.return,
             headers,
           })
         )
    );
  };