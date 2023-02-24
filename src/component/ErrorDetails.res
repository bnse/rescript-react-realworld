@react.component
let make = (~label: string, ~error: option<array<string>>) =>
  error
  ->Option.map(message =>
    message
    ->Js.Array2.map(message => <li key=message> {`${label} ${message}`->React.string} </li>)
    ->React.array
  )
  ->Option.getWithDefault(React.null)
