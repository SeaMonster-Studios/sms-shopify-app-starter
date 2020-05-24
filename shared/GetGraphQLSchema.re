Dotenv.(config(~options=configInput(~path="../.env", ()), ()));

[@bs.val] [@bs.scope ("process", "env")]
external hasuraAdminSecret: Js.Nullable.t(string) = "HASURA_ADMIN_SECRET";
let hasuraAdminSecret = hasuraAdminSecret->Js.Nullable.toOption;

[@bs.val] [@bs.scope ("process", "env")]
external graphEndpoint: Js.Nullable.t(string) = "GRAPHQL_ENDPOINT";
let graphEndpoint = graphEndpoint->Js.Nullable.toOption;

switch (graphEndpoint, hasuraAdminSecret) {
| (Some(graphEndpoint), Some(hasuraAdminSecret)) =>
  let header = "'x-hasura-admin-secret=" ++ hasuraAdminSecret ++ "'";
  Node.Child_process.execSync(
    {j|npx get-graphql-schema $graphEndpoint -j -h $header > ../graphql_schema.json|j},
    Node.Child_process.option(),
  )
  ->ignore;
| _ =>
  Js.log(
    "Missing GRAPHQL_ENDPOINT and/or HASURA_ADMIN_SECRET environment variables",
  )
};