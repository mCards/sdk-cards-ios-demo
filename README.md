# mCards iOS Cards SDK Demo App

The mCards iOS Cards SDK Demo App demonstrates how to use the mCards iOS Cards SDK which provides the following functionality:
1. Digital Provisioning: Adding a Card to the Apple Wallet
	- Check if a card is in the digital wallet
	- Add a card to the digital wallet
	- Activate a card that's been added (but not activated) to the digital wallet
	- Remove a card from the digital wallet
2. Fetch a user's mCard list
3. Fetch the balances for a given mCard
4. Display an mCard's details

# Importing
The CardsSDK can be imported via SPM (Swift Package Manager).

- In XCode, go to: File -> Add Package Dependencies
- In the search bar enter: `https://github.com/Wantsa/sdk-cards-ios-framework`
- Choose a dependency rule (e.g. `Up to Next Major` with `1.0.0`)
- Click `Add Package`

- The CoreSDK also needs to be imported for the CardsSDK to work. Follow the same steps above and enter: `https://github.com/Wantsa/sdk-model-ios-framework` in the search bar
- The AuthSDK also needs to be imported. Follow the same steps above and enter: `https://github.com/Wantsa/sdk-auth-ios-framework` in the search bar

# Usage
Implementing apps must take additional steps if using the Auth SDK and Auth0 as a token provider. In Xcode:
- Go to the info tab of your app target settings
- In the `URL Types` section, click the `+` button to add a new entry
- Enter `auth0` into the `Identifier` field and `$(PRODUCT_BUNDLE_IDENTIFIER)` in the `URL Schemes` field. Leave other fields blank.

# Documentation
[Documentation site](https://mcards.readme.io/)

[SDKs conceptual documentation](https://mcards.readme.io/docs/mcards-sdk-overview)
