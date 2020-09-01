module Provider = {
  @bs.module("@shopify/polaris") @react.component
  external make: (~children: React.element) => React.element = "AppProvider"
}

module Card = {
  @bs.module("@shopify/polaris") @react.component
  external make: unit => React.element = "Card"
}
