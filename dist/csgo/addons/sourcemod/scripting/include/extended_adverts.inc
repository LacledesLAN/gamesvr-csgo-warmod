#if defined _extended_adverts_included
	#endinput
#endif

public SharedPlugin:__pl_adv_adverts = 
{
	name = "adv_adverts",
#if defined ADVERT_SOURCE2009
	file = "adv_adverts_tf2.smx",
#else
	file = "adv_adverts_nontf2.smx",
#endif
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

/**
 * 
 * Checks whether an advetisements exists or not.
 * 
 * @param advertId		The ID of the advert that is being checked against
 * 
 * @return				True if the advert exists, false otherwise.
 * 
 */

native bool:AdvertExists(const String:advertId[]);

/**
 * 
 * Deletes an advert from the advert list
 * 
 * @param advertId		The ID of the advert that should be deleted
 * 
 * @return				True on success, false otherwise (May be because of other interfereing plugins).
 * 
 */

native bool:DeleteAdvert(const String:advertId[]);

#if defined ADVERT_SOURCE2009

/**
 * 
 * Reloads the advertisement config.
 * 
 * @param ads			Should we reload all the advertisements' config?
 * @param tsayColors	Should we reload all the topsay colors' config?
 * @param chatColors	Should we reload all the extra chat colors' config?
 * 
 * @note				This is not neccessary for MySQL (Or any other custom) approaches to adding advertisements.
 * @note				This is only necessary to reload a flatfile configuration.
 * 
 * @noreturn
 * 
 */

native ReloadAdverts(bool:ads = true, bool:tsayColors = true, bool:chatColors = true);

#else

/**
 * 
 * Reloads the advertisement config.
 * 
 * @param ads			Should we reload all the advertisements' config?
 * @param tsayColors	Should we reload all the topsay colors' config?
 * 
 * @note				This is not neccessary for MySQL (Or any other custom) approaches to adding advertisements.
 * @note				This is only necessary to reload a flatfile configuration.
 * 
 * @noreturn
 * 
 */

native ReloadAdverts(bool:ads = true, bool:tsayColors = true);

#endif

/**
 * 
 * Shows an advertisement
 * 
 * @param advertId		The ID of the advertisement that needs to be shown. NULL_STRING if you want to show the next advertisement.
 * @param jumpTo		If true, then the position will return to the old order after the new advert has been shown. If false it wont.
 * 
 * @return				True if the advert was shown, false otherwise.
 * 
 */

native bool:ShowAdvert(const String:advertId[] = NULL_STRING, bool:jumpTo = false);

/**
 * 
 * Adds an advertisement to the advertisements list
 * 
 * @param advertId		The ID of the advertisement (As a string, does not need to be numerical)
 * @param advertType	The string that contains the letters for the type of the advertisement
 * @param advertText	The unedited string (with tags) of the advertisement
 * @param advertFlags	The bitwise representation of the admin flags that a client should have to view the ad.
 * @param noFlags		The bitwise representations of the admin flags that a client should not have to view the ad.
 * @param jumpTo		If true, then the position will return to the old order after the new advert has been shown. If false it wont.
 * @param replace		If true, then it will replace any existing adverts with the same advertId.
 * 
 * @return				True if the advert was successfully created, false if there is already an advert with the same name and was not replaced.
 * 
 */

native bool:AddAdvert(const String:advertId[], const String:advertType[], const String:advertText[], advertFlags = -1, noFlags = -1, bool:jumpTo = false, bool:replace = false);

/**
 * 
 * Adds a color to the top colors trie.
 * 
 * @param colorName		The color name (without curly brackets), this is the name that you will use inside of the '{' and '}' tags in the config.
 * @param red			The red value.
 * @param green			The green value
 * @param blue			The blue value
 * @param alpha			The alpha value
 * @param replace		If a color with an equal name was found, should we replace it?
 * 
 * @return				True on success, false on failure
 * 
 */

native bool:AddExtraTopColor(String:colorName[], red, green, blue, alpha, bool:replace = true);

/**
 * 
 * Checks if a client can view the advertisement
 * 
 * @param client		The client index to check against
 * @param flagBits		The flagBits to check if client has, -1 if none.
 * 
 * @note				This is of great use in the forward OnPreClientReplace
 * 
 * @return				True if client can view the advertisement, false otherwise.
 * 
 */
native bool:Client_CanViewAds(client, flagBits = -1, noFlagBits = -1);

#if defined ADVERT_SOURCE2009
/**
 * 
 * Adds a color to the extra chat colors trie.
 * 
 * @param colorName		The color name (without curly brackets), this is the name that you will use inside of the '{' and '}' tags in the config.
 * @param hex			The exadecimal representation of the color (0xRRGGBB)
 * 
 * @note				To use this native, you need to have #define ADVERT_SOURCE2009 before including this file.
 * 
 * @return				True if the color was added, false if a color with an equal name was found or another issue occured (Such as a blockage by an external plugin)
 */
native bool:AddExtraChatColor(String:colorName[], hex);
#endif


/**
 * 
 * Called before replacing the advert tags (The tags inside of '{' and '}' braces.
 * 
 * @param advertId		The id of the advertisement as specified in the config
 * @param advertType	The string containing the advertisement type(s) as specified in the config. (By-Ref)
 * @param advertText	The text string of the advertisement including all the tags inside of '{' and '}' braces. (By-Ref)
 * @param advertFlags	The flag bits that a client needs to have to view this advertisement. (By-Ref)
 * 
 * @note 				All information passed on in this forward can be modified and changed, as it is all by-ref.
 * @note				Anything returned other than Plugin_Continue in this forward will make the advert stop and not go through.
 * 
 * @return				Plugin_Continue to allow the advert go through. Anything else would stop the advert from showing.
 * 
 */
forward Action:OnAdvertPreReplace(const String:advertId[], String:advertType[], String:advertText[], &advertFlags);

/**
 * 
 * Called before replacing the {CLIENT_} tags in the advert.
 * 
 * @param client		The client id of the client that is going to be shown the advert to (If the client passes the admin flag check)
 * @param advertId		The id of the advertisement as specified in the config. 
 * @param advertType	The string containing the advertisement type(s) as specified in the config. 
 * @param advertText	The text string of the advertisement including all the {CLIENT_} tags. (By-Ref)
 * @param advertFlags	The flag bits that a client needs to have to view this advertisement. (By-Ref)
 * 
 * @note 				The only two values pass by reference that can be modified are advertText and advertFlags.
 * 
 * @return				True if client will view the advertisement. False otherwise.
 * 
 */

forward bool:OnAdvertPreClientReplace(client, const String:advertId[], const String:advertType, String:advertText, &advertFlags);

/**
 * 
 * Called after the advertisement has been shown.
 * 
 * @param advertId		The id of the advertisement as specified in the config.
 * @param advertType	The string containing the advertisement type(s) as specified in the config.
 * @param advertText	The text string of the advertisement with all tags replaced.
 * @param advertFlags	The flag bits that a client needed to have to view this advert.
 * 
 * @note				No information can be modified to be shown to the clients at this point, as this is called after the advertisment.
 * 
 * @noreturn
 * 
 */
forward OnPostAdvertisementShown(const String:advertId[], const String:advertType[], const String:advertText[], advertFlags);

#if defined ADVERT_SOURCE2009
/**
 * 
 * Called right before an extra chat color is added.
 * 
 * @param colorName		The color's name without curly brackets (By Ref)
 * @param maxlength		The maxlength of the colorName string.
 * @param hex			The hexadecimal represenation of the color. (By Ref)
 * 
 * @return 				Plugin_Continue to allow the color addition, anything else blocks the color addition.
 * 
 */

forward Action:OnAddChatColorPre(String:colorName[], maxlength, &hex);

/**
 * 
 * Called right after an extra chat color is added.
 * 
 * @param colorName		The color's name (without curly brackets)
 * @param hex			The hexadecimal represenation of the color.
 * 
 * @noreturn
 * 
 */

forward OnAddChatColorPost(const String:colorName[], &hex);

#endif

/**
 * 
 * Called right before an extra top color is added.
 * 
 * @param colorName		The color name (without curly brackets), this is the name that you will use inside of the '{' and '}' tags in the config. (By-Ref)
 * @param maxlength		The maxlength of the colorName string.
 * @param red			The red value. (By-Ref)
 * @param green			The green value. (By-Ref)
 * @param blue			The blue value. (By-Ref)
 * @param alpha			The alpha value. (By-Ref)
 * @param replace		If a color with an equal name was found, should we replace it? (By-Ref)
 * 
 * @return 				Plugin_Continue to allow the color addition, anything else blocks the color addition.
 * 
 */
forward Action:OnAddTopColorPre(String:colorName[], maxlength, &red, &green, &blue, &alpha, &bool:replace);

/**
 * 
 * Called right after an extra top color is added.
 * 
 * @param colorName		The color name (without curly brackets), this is the name that you will use inside of the '{' and '}' tags in the config.
 * @param red			The red value.
 * @param green			The green value
 * @param blue			The blue value
 * @param alpha			The alpha value
 * @param replace		If a color with an equal name was found, should we replace it?
 * 
 * @noreturn
 * 
 */
forward OnAddTopColorPost(const String:colorName[], red, green, blue, alpha, bool:replace);

/**
 * 
 * Called right before an advert is added
 * 
 * @param advertId		The ID of the advertisement (As a string, does not need to be numerical) (By-Ref)
 * @param id_ml			The maxlength of the advertId parameter
 * @param advertType	The string that contains the letters for the type of the advertisement (By-Ref)
 * @param type_ml		The maxlength of the advertType parameter
 * @param advertText	The unedited string (with tags) of the advertisement (By-Ref)
 * @param text_ml		The maxlength of the advertText parameter
 * @param advertFlags	The bitwise representation of the admin flags that a client should have to view the ad. (By-Ref)
 * @param noFlags		The bitwise representations of the admin flags that a client should not have to view the ad. (By-Ref)
 * @param jumpTo		If true, then the position will return to the old order after the new advert has been shown. If false it wont. (By-Ref)
 * @param replace		If true, then it will replace any existing adverts with the same advertId. (By-Ref)
 * 
 * @return 				Plugin_Continue to allow the advert addition, anything else blocks the advert addition.
 * 
 */
forward Action:OnAddAdvertPre(String:advertId[], id_ml, String:advertType[], type_ml, String:advertText[], text_ml, &advertFlags, &noFlags, &bool:jumpTo, &bool:replace);


/**
 * 
 * Called right before an advert is added
 * 
 * @param advertId		The ID of the advertisement (As a string, does not need to be numerical)
 * @param advertType	The string that contains the letters for the type of the advertisement
 * @param advertText	The unedited string (with tags) of the advertisement
 * @param advertFlags	The bitwise representation of the admin flags that a client should have to view the ad.
 * @param noFlags		The bitwise representations of the admin flags that a client should not have to view the ad.
 * @param jumpTo		If true, then the position will return to the old order after the new advert has been shown. If false it wont.
 * @param replace		If true, then it will replace any existing adverts with the same advertId.
 * 
 * @noreturn
 * 
 */
forward OnAddAdvertPost(const String:advertId[], const String:advertType[], const String:advertText[], advertFlags, noFlags, const bool:jumpTo, const bool:replace);


/**
 * 
 * Called right before an advert is deleted
 * 
 * @param advertId		The ID of the advertisement (As a string, does not need to be numerical) (By-Ref)
 * @param maxlength		The maxlength of the advertId parameter.
 * 
 * @note				Please keep in mind that this forward gets called before any checks have been applied.
 * @note				You will need to use checks such as AdvertExists() if you want to use this forward effectively.
 * 
 * @return				Plugin_Continue to allow the advert deletion, anything else blocks the advert deletion.
 * 
 */

forward Action:OnPreDeleteAdvert(String:advertId[], maxlength);

/**
 * 
 * Called right after an advert is deleted
 * 
 * @param advertId		The ID of the advertisement (As a string, does not need to be numerical)
 * 
 * @return				Plugin_Continue to allow the advert deletion, anything else blocks the advert deletion.
 * 
 */

forward OnPostDeleteAdvert(const String:advertId[]);

public __pl_adv_adverts_SetNTVOptional()
{
	MarkNativeAsOptional("AddExtraTopColor");
	MarkNativeAsOptional("Client_CanViewAds");
	MarkNativeAsOptional("DeleteAdvert");
	MarkNativeAsOptional("ReloadAdverts");
	MarkNativeAsOptional("ShowAdvert");
	MarkNativeAsOptional("AddAdvert");
#if defined ADVERT_SOURCE2009
	MarkNativeAsOptional("AddExtraChatColor");
#endif
}