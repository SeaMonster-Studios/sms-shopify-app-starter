open Belt;
open SharedUtils;
open FUtils;

switch (sentryEnv, sentryDsn) {
| (Some(environment), Some(dsn)) =>
  if (sentryEnv->Option.getWithDefault("") == "production") {
    SS.Sentry.(
      Browser.make(
        options(
          ~dsn,
          ~environment,
          ~ignoreErrors=[|[%re "/.*localhost.* /"]|],
          ~blacklistUrls=[|[%re "/.*localhost.* /"]|],
          (),
        )
        ->Js.Nullable.return,
      )
    );
  }
| _ =>
  Js.log(
    "SENTRY_DSN and/or SENTRY_ENV environment variables are missing. Please add them to ensure reporting is working correctly for Sentry in production",
  )
};

[@bs.val] external document: Js.t({..}) = "document";

let makeContainer = () => {
  let container = document##createElement("div");
  container##className #= "container";

  let content = document##createElement("div");
  content##className #= "containerContent";

  let () = container##appendChild(content);
  let () = document##body##appendChild(container);

  content;
};

ReactDOMRe.render(<AppStore> <App /> </AppStore>, makeContainer());