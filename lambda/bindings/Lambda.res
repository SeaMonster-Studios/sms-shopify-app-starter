open Belt

module Context = {
  type app_metadata = {provider: string}

  type user_metadata = {full_name: string}

  type user = {
    exp: int,
    sub: string,
    email: string,
    app_metadata: app_metadata,
    user_metadata: user_metadata,
  }

  type clientContext = {user: Js.Nullable.t<user>}
  type t = {
    "clientContext": Js.Nullable.t<clientContext>,
    @bs.meth
    "redirect": string => unit,
    @bs.set
    "body": string,
    @bs.set
    "statusCode": int,
  }

  let getUser = (context: t) =>
    context["clientContext"]
    ->Js.Nullable.toOption
    ->Option.flatMap(context => context.user->Js.Nullable.toOption)
}

type headers = {
  "Access-Control-Allow-Origin": Js.Nullable.t<string>,
  "Access-Control-Allow-Credentials": Js.Nullable.t<bool>,
  "Location": Js.Nullable.t<string>,
}

let headers = (
  ~allowOrigin: option<string>=?,
  ~allowCredentials: option<bool>=?,
  ~location: option<string>=?,
  (),
) =>
  {
    "Access-Control-Allow-Origin": switch allowOrigin {
    | Some(value) => value->Js.Nullable.return
    | None => Js.Nullable.null
    },
    "Access-Control-Allow-Credentials": switch allowCredentials {
    | Some(value) => value->Js.Nullable.return
    | None => Js.Nullable.null
    },
    "Location": switch location {
    | Some(value) => value->Js.Nullable.return
    | None => Js.Nullable.null
    },
  }

type return = {
  statusCode: int,
  body: Js.Nullable.t<string>,
  headers: headers,
}

type handler<'a> = ('a, Context.t) => Js.Promise.t<return>

type queryStringParameters = {
  shop: Js.Nullable.t<string>,
  redirect: Js.Nullable.t<string>,
  hmac: Js.Nullable.t<string>,
  code: Js.Nullable.t<string>,
  timestamp: Js.Nullable.t<string>,
  state: Js.Nullable.t<string>,
  session: Js.Nullable.t<string>,
}

type event<'b> = {
  queryStringParameters: Js.Nullable.t<queryStringParameters>,
  headers: 'b,
}

type env = {
  apiKey: string,
  apiSecret: string,
  redirect: string,
  scopes: string,
  hasuraAdminSecret: string,
  appUrl: string,
}

type verified = {
  env: env,
  params: queryStringParameters,
  isInstalled: bool,
  shop: string,
}
