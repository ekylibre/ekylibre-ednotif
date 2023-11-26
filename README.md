# Ednotif

Plugin for integrate animal's automatic data from EDE.

You need a cipher key to operate this plugin into your .env file in Ekylibre

You can generate it by 

rake cipher:aes

In your .env

INTEGRATION_CIPHER_BASE64_KEY = "YOUR KEY"

# Specification

https://idele.fr/detail-article/ipg-bovine-cahier-des-charges-des-evolutions-des-logiciels-des-detenteurs-eleveurs

https://idele.fr/identification-tracabilite/?eID=cmis_download&oID=workspace%3A%2F%2FSpacesStore%2F0569ba19-58ba-4d56-97b1-9567e80d0a8b&cHash=e955faf90cf327b3ce85d6c2370e3f96


# Documentation

All method are coming from xsd/xml files in `lib/ekylibre/ednotif/resources`

# Usage

## Activate the plugins

Suposed your are in Charente Maritime (17)

Numéro de cheptel is like '**FR17**123456'

Numéro de votre EDE is like '**E17**0'

Identifiant are supply by your local EDE but corresponding to farm number '**17**123456' 

Mot de passe are supply by your local EDE.

## Use the get inventory button in the `/backend/animals` page