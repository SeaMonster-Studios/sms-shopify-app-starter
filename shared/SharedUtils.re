[@bs.val] [@bs.scope ("process", "env")]
external graphEndpoint: Js.Nullable.t(string) = "GRAPHQL_ENDPOINT";
let graphEndpoint = graphEndpoint->Js.Nullable.toOption;

[@bs.val] [@bs.scope ("process", "env")]
external dsn: Js.Nullable.t(string) = "SENTRY_DSN";
let sentryDsn = dsn->Js.Nullable.toOption;

[@bs.val] [@bs.scope ("process", "env")]
external sentryEnv: Js.Nullable.t(string) = "SENTRY_ENV";
let sentryEnv = sentryEnv->Js.Nullable.toOption;