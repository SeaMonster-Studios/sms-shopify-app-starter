open Belt

type apiKey = string
type shopOrigin = string

// https://shopify.dev/tools/app-bridge/react-components
@bs.deriving(jsConverter)
type target = [#ADMIN_PATH | #REMOTE | #APP]

@bs.deriving(abstract)
type actionProps = {
  @bs.optional
  content: string,
  @bs.optional
  destructive: bool,
  @bs.optional
  disabled: bool,
  @bs.optional @bs.as("external")
  external_: bool,
  @bs.optional
  target: Js.Nullable.t<string>,
  @bs.optional
  url: string,
  @bs.optional
  onAction: unit => unit,
}
let actionProps = (
  ~content: option<string>=?,
  ~destructive: option<bool>=?,
  ~disabled: option<bool>=?,
  ~external_: option<bool>=?,
  ~target: option<target>=?,
  ~url: option<string>=?,
  ~onAction: option<unit => unit>=?,
  (),
) =>
  actionProps(
    ~content?,
    ~destructive?,
    ~disabled?,
    ~external_?,
    ~target=target->Option.mapWithDefault(Js.Nullable.null, target =>
      target->targetToJs->Js.Nullable.return
    ),
    ~url?,
    ~onAction?,
  )

type actionGroup = {
  title: string,
  actions: array<actionProps>,
}

@bs.deriving(abstract)
type breadcrumb = {
  @bs.optional
  name: string,
  @bs.optional
  url: string,
  @bs.optional
  target: Js.Nullable.t<string>,
  @bs.optional
  onAction: unit => unit,
}
let breadcrumb = (
  ~name: option<string>=?,
  ~url: option<string>=?,
  ~target: option<target>=?,
  ~onAction: option<unit => unit>=?,
) =>
  breadcrumb(
    ~name?,
    ~url?,
    ~onAction?,
    ~target=target->Option.mapWithDefault(Js.Nullable.null, target =>
      target->targetToJs->Js.Nullable.return
    ),
  )

type app

@bs.deriving(abstract)
type config = {
  shopOrigin: shopOrigin,
  apiKey: apiKey,
  @bs.optional
  forceRedirect: bool,
}

type selectPayload

module Context = {
  @bs.module("@shopify/app-bridge-react")
  external make: React.Context.t<'a> = "Context"
}

module Provider = {
  @bs.module("@shopify/app-bridge-react") @react.component
  external make: (~config: config, ~children: React.element) => React.element = "Provider"
}

module Consumer = {
  @bs.module("@shopify/app-bridge-react") @bs.scope("Context") @react.component
  external make: (~children: Js.Nullable.t<app> => React.element) => React.element = "Consumer"
}

module TitleBar = {
  @bs.module("@shopify/app-bridge-react") @react.component
  external make: (
    ~title: string,
    ~breadcrumbs: array<breadcrumb>=?,
    ~primaryAction: actionProps=?,
    ~secondaryActions: array<actionProps>=?,
    ~actionGroups: array<actionGroup>=?,
  ) => React.element = "TitleBar"
}

module Toast = {
  @bs.module("@shopify/app-bridge-react") @react.component
  external make: (
    ~content: string,
    ~duration: int=?,
    ~error: bool=?,
    ~onDismiss: unit => unit=?,
  ) => React.element = "Loading"
}

module Loading = {
  @bs.module("@shopify/app-bridge-react") @react.component
  external make: unit => React.element = "Loading"
}

module ResourcePicker = {
  @bs.module("@shopify/app-bridge-react") @react.component
  external make: (
    ~open_: bool,
    ~resourceType: @bs.string [#Product | #ProductVariant | #Collection],
    ~initialQuery: string=?,
    ~showHidden: bool=?,
    ~allowMultiple: bool=?,
    ~showVariants: bool=?,
    ~onSelection: selectPayload => unit=?,
    ~onCancel: unit => unit=?,
  ) => React.element = "ResourcePicker"
}

module Modal = {
  @bs.module("@shopify/app-bridge-react") @react.component
  external make: (
    ~open_: bool,
    ~src: string=?,
    ~title: string=?,
    ~size: @bs.string [#Small | #Medium | #Large]=?,
    ~message: string=?,
    ~primaryAction: actionProps=?,
    ~seconaryAction: array<actionProps>=?,
    ~onClose: unit => unit=?,
  ) => React.element = "Modal"
}
