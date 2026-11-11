# mCards iOS Cards SDK Demo

Demonstrates wallet provisioning and the Marqeta set/change PIN WebView using the customer SDKs.

## Dependencies

- [CardsSDK 1.1.19](https://github.com/mCards/sdk-cards-ios-framework/tree/1.1.19), including CoreSDK 1.4.8.
- [AuthSDK 1.1.6](https://github.com/mCards/sdk-auth-ios-framework/tree/1.1.6) for this demo's Auth0 login.

The project and checked-in SPM lockfile use only mCards repositories. CoreSDK is supplied by the
CardsSDK package; remove any separate CoreSDK/model package reference when migrating an existing
app to avoid duplicate modules. No Wantsa access is required.

Open `CardsSDKDemo.xcodeproj` and resolve package dependencies in Xcode. For an existing app,
add `https://github.com/mCards/sdk-cards-ios-framework`, choose version 1.1.19 or later, and
select `CardsSDK`. Add the customer AuthSDK separately only when using it as your token provider.

## Configure and run

Replace the sample Auth0 client ID, domain and audience in `ViewController.setupAuthSDK()` with
the values assigned to your program and environment by mCards. Configure the Auth0 callback URL
for your bundle identifier. The project includes an `auth0` URL type with the app's bundle ID.
Use an assigned fictional UAT identity and an active Marqeta card; this repository does not
provide a shared test account or SMS inbox.

1. Log in. The app fetches the cardholder's cards.
2. Choose **Set / change PIN** in the navigation bar and select an active Marqeta card.
3. The demo refreshes tokens and calls `showCardPinManagement(card:webView:jwts:listener:)`.
4. `.setPin` success dismisses the WebView and refreshes cards. An activation or reveal event
   does not complete PIN setup. The issuer can still report a pending PIN immediately afterwards.
5. Component errors leave the WebView open for retry. Navigation errors show an alert; **Close**
   remains available even when the page cannot load.

The same flow sets a first PIN or changes an existing one. The SDK installs the JavaScript
bridge; the app never handles the PIN value. Component styling comes from the hosted page;
there are no `success_url` or theme arguments.

Wallet provisioning requires Apple issuer entitlements. A simulator build verifies SDK
integration but does not exercise wallet provisioning or an authenticated PIN session.

## Build check

```sh
xcodebuild -project CardsSDKDemo.xcodeproj -scheme CardsSDKDemo \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

[SDK documentation](https://mcards.readme.io/docs/mcards-sdk-overview)
