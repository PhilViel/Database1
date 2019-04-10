/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                :	DL_UN_Subscriber
Description        :	Supprime un souscripteur
Valeurs de retours :	>0  : Tout à fonctionné
                      <=0 : Erreur SQL
								-1 : 	Erreur il y a des enregistrements 200 expédiés
								-2 : 	Erreur à la création du log
								-3 : 	Erreur à la suppression des enregistrements 200 non-expédiés
								-4 : 	Erreur à la suppression du souscripteur
Note               :						2004-05-28	Bruno Lapointe			Création
							ADX0000594	IA	2004-11-24	Bruno Lapointe	Log
							ADX0000826	IA	2006-03-14	Bruno Lapointe	Adaptation des souscripteurs pour PCEE 4.3
											2008-11-07  Patrick Robitaille			Ajout du profil souscripteur
											2009-01-09	Donald Huppé				Modif du JOIN en LEFT JOIN sur la table tblCONV_PreferenceSuivi
											2011-05-11	Corentin Menthonnex	Ajout de nouveaux champs souscripteur
											2011-06-23	Corentin Menthonnex	Ajout de nouveaux champs souscripteur
											2011-10-24	Christian Chénard		Ajout des champs iID_Identite_Souscripteur et vcIdentiteVerifieeDescription dans la journalisation (CRQ_Log)
											2011-11-02	Christian Chénard		Ajout du champ bAutorisation_Resiliation
											2014-03-06	Pierre-Luc Simard		Retrait du log des téléphone Pager et Wattline
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Subscriber] (
	@ConnectID INTEGER, -- ID Unique de connection de l'usager
	@SubscriberID INTEGER) -- ID Unique du souscripteur
AS
BEGIN
	DECLARE
		@iResultID INTEGER,
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1),
		@iCodeErr INTEGER
	
	SET @cSep = CHAR(30)

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- S'assure qu'il n'y est pas d'enregistrements 200 expédiés
	IF EXISTS (
		SELECT *
		FROM Un_CESP200
		WHERE HumanID = @SubscriberID
			AND tiType = 4
			AND iCESPSendFileID IS NOT NULL
			)
		SET @SubscriberID = -1

	IF @SubscriberID > 0
	BEGIN
		-- Insère un log de l'objet inséré.
		INSERT INTO CRQ_Log (
			ConnectID,
			LogTableName,
			LogCodeID,
			LogTime,
			LogActionID,
			LogDesc,
			LogText)
			SELECT
				@ConnectID,
				'Un_Subscriber',
				@SubscriberID,
				GETDATE(),
				LA.LogActionID,
				LogDesc = 'Souscripteur : '+H.LastName+', '+H.FirstName,
				LogText =
					CASE 
						WHEN ISNULL(H.FirstName,'') = '' THEN ''
					ELSE 'FirstName'+@cSep+H.FirstName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.LastName,'') = '' THEN ''
					ELSE 'LastName'+@cSep+H.LastName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.OrigName,'') = '' THEN ''
					ELSE 'OrigName'+@cSep+H.OrigName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.Initial,'') = '' THEN ''
					ELSE 'Initial'+@cSep+H.Initial+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.BirthDate,0) <= 0 THEN ''
					ELSE 'BirthDate'+@cSep+CONVERT(CHAR(10), H.BirthDate, 20)+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.DeathDate,0) <= 0 THEN ''
					ELSE 'DeathDate'+@cSep+CONVERT(CHAR(10), H.DeathDate, 20)+@cSep+CHAR(13)+CHAR(10)
					END+
					'LangID'+@cSep+H.LangID+@cSep+L.LangName+@cSep+CHAR(13)+CHAR(10)+
					'SexID'+@cSep+H.SexID+@cSep+Sx.SexName+@cSep+CHAR(13)+CHAR(10)+
					'CivilID'+@cSep+H.CivilID+@cSep+CS.CivilStatusName+@cSep+CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(H.SocialNumber,'') = '' THEN ''
					ELSE 'SocialNumber'+@cSep+H.SocialNumber+@cSep+CHAR(13)+CHAR(10)
					END+
					'ResidID'+@cSep+H.ResidID+@cSep+R.CountryName+@cSep+CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(H.DriverLicenseNo,'') = '' THEN ''
					ELSE 'DriverLicenseNo'+@cSep+H.DriverLicenseNo+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.WebSite,'') = '' THEN ''
					ELSE 'WebSite'+@cSep+H.WebSite+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.CompanyName,'') = '' THEN ''
					ELSE 'CompanyName'+@cSep+H.CompanyName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.CourtesyTitle,'') = '' THEN ''
					ELSE 'CourtesyTitle'+@cSep+H.CourtesyTitle+@cSep+CHAR(13)+CHAR(10)
					END+
					'UsingSocialNumber'+@cSep+CAST(ISNULL(H.UsingSocialNumber,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(H.UsingSocialNumber,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'SharePersonalInfo'+@cSep+CAST(ISNULL(H.SharePersonalInfo,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(H.SharePersonalInfo,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'MarketingMaterial'+@cSep+CAST(ISNULL(H.MarketingMaterial,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(H.MarketingMaterial,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'IsCompany'+@cSep+CAST(ISNULL(H.IsCompany,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(H.IsCompany,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(A.Address,'') = '' THEN ''
					ELSE 'Address'+@cSep+A.Address+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.City,'') = '' THEN ''
					ELSE 'City'+@cSep+A.City+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.StateName,'') = '' THEN ''
					ELSE 'StateName'+@cSep+A.StateName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.CountryID,'') = '' THEN ''
					ELSE 'CountryID'+@cSep+A.CountryID+@cSep+C.CountryName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.ZipCode,'') = '' THEN ''
					ELSE 'ZipCode'+@cSep+A.ZipCode+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.Phone1,'') = '' THEN ''
					ELSE 'Phone1'+@cSep+A.Phone1+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.Phone2,'') = '' THEN ''
					ELSE 'Phone2'+@cSep+A.Phone2+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.Fax,'') = '' THEN ''
					ELSE 'Fax'+@cSep+A.Fax+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.Mobile,'') = '' THEN ''
					ELSE 'Mobile'+@cSep+A.Mobile+@cSep+CHAR(13)+CHAR(10)
					END+/*
					CASE 
						WHEN ISNULL(A.WattLine,'') = '' THEN ''
					ELSE 'WattLine'+@cSep+A.WattLine+@cSep+CHAR(13)+CHAR(10)
					END+*/
					CASE 
						WHEN ISNULL(A.OtherTel,'') = '' THEN ''
					ELSE 'OtherTel'+@cSep+A.OtherTel+@cSep+CHAR(13)+CHAR(10)
					END+/*
					CASE 
						WHEN ISNULL(A.Pager,'') = '' THEN ''
					ELSE 'Pager'+@cSep+A.Pager+@cSep+CHAR(13)+CHAR(10)
					END+*/
					CASE 
						WHEN ISNULL(A.EMail,'') = '' THEN ''
					ELSE 'EMail'+@cSep+A.EMail+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(S.RepID,0) <= 0 THEN ''
					ELSE 'RepID'+@cSep+CAST(S.RepID AS VARCHAR)+@cSep+ISNULL(HR.LastName+', '+HR.FirstName,'')+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(S.StateID,0) <= 0 THEN ''
					ELSE 'StateID'+@cSep+CAST(S.StateID AS VARCHAR)+@cSep+ISNULL(St.StateName,'')+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(S.ScholarshipLevelID,'') = '' THEN ''
					ELSE 
						'ScholarshipLevelID'+@cSep+S.ScholarshipLevelID+@cSep+
						CASE S.ScholarshipLevelID
							WHEN 'UNK' THEN 'Inconnu'
							WHEN 'NDI' THEN 'Non diplômé'
							WHEN 'SEC' THEN 'Secondaire'
							WHEN 'COL' THEN 'Collège'
							WHEN 'UNI' THEN 'Université'
						ELSE ''
						END+@cSep+
						CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(S.AnnualIncome,0) <= 0 THEN ''
					ELSE 'AnnualIncome'+@cSep+CAST(S.AnnualIncome AS VARCHAR)+@cSep+CHAR(13)+CHAR(10)
					END+
					'SemiAnnualStatement'+@cSep+CAST(ISNULL(S.SemiAnnualStatement,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(S.SemiAnnualStatement,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(S.BirthLangID,'') = '' THEN ''
					ELSE 'BirthLangID'+@cSep+S.BirthLangID+@cSep+ISNULL(WL.WorldLanguage,'')+@cSep+CHAR(13)+CHAR(10)
					END+
					'tiCESPState'+@cSep+CAST(ISNULL(S.tiCESPState,0) AS VARCHAR)+@cSep+
					CASE 
						WHEN ISNULL(S.tiCESPState,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE
						WHEN ISNULL(H.cID_Pays_Origine,'') = '' THEN ''
					ELSE 'PaysOrigineID'+@cSep+H.cID_Pays_Origine+@cSep+CO.CountryName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE
						WHEN ISNULL(S.iID_Preference_Suivi,0) <= 0 THEN ''
					ELSE 'PreferenceSuiviID'+@cSep+CAST(ISNULL(S.iID_Preference_Suivi,0)AS VARCHAR)+@cSep+ISNULL(PS.vcDescription,'')+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.StateCompanyNo,'') = '' THEN ''
					ELSE 'NEQ'+@cSep+H.StateCompanyNo+@cSep+CHAR(13)+CHAR(10)
					END+

					-- 2011-05-11 : + 2011-12 - CM
					CASE 
						WHEN ISNULL(H.vcOccupation,'') = '' THEN ''
					ELSE 'vcOccupation'+@cSep+H.vcOccupation+@cSep+CHAR(13)+CHAR(10)
					END+
					
					-- 2011-05-11 : + 2011-12 - CM
					CASE 
						WHEN ISNULL(H.vcEmployeur,'') = '' THEN ''
					ELSE 'vcEmployeur'+@cSep+H.vcEmployeur+@cSep+CHAR(13)+CHAR(10)
					END+
					
					-- 2011-05-11 : + 2011-12 - CM+					
					CASE 
						WHEN ISNULL(H.tiNbAnneesService,0) = 0 THEN ''
					ELSE 'tiNbAnneesService'+@cSep+CAST(H.tiNbAnneesService AS VARCHAR)+@cSep+CHAR(13)+CHAR(10)
					END+

					-- 2011-05-11 : + 2011-12 - CM
					'bRapport_Annuel_Direction'+@cSep+CAST(ISNULL(S.bRapport_Annuel_Direction,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(S.bRapport_Annuel_Direction,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+CHAR(13)+CHAR(10)+

					-- 2011-05-11 : + 2011-12 - CM
					'bEtats_Financiers_Annuels'+@cSep+CAST(ISNULL(S.bEtats_Financiers_Annuels,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(S.bEtats_Financiers_Annuels,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+CHAR(13)+CHAR(10)+

					-- 2011-06-23 : + 2011-12 - CM
					'bEtats_Financiers_Semestriels'+@cSep+CAST(ISNULL(S.bEtats_Financiers_Semestriels,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(S.bEtats_Financiers_Semestriels,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+CHAR(13)+CHAR(10)+
					'iID_Identite_Souscripteur'+@cSep+CAST(ISNULL(S.iID_Identite_Souscripteur,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(S.iID_Identite_Souscripteur,0) = 0 THEN ''
					ELSE IDS.vcDescription+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(S.vcIdentiteVerifieeDescription,'') = '' THEN ''
					ELSE
						'vcIdentiteVerifieeDescription'+@cSep+S.vcIdentiteVerifieeDescription+@cSep+CHAR(13)+CHAR(10)
					END+
										
					'bAutorisation_Resiliation'+@cSep+CAST(ISNULL(S.bAutorisation_Resiliation,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(S.bRapport_Annuel_Direction,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+CHAR(13)+CHAR(10)		
				FROM dbo.Un_Subscriber S
				JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
				JOIN Mo_Lang L ON L.LangID = H.LangID
				JOIN Mo_Sex Sx ON Sx.LangID = H.LangID AND Sx.SexID = H.SexID
				JOIN Mo_CivilStatus CS ON CS.LangID = H.LangID AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'D'
				JOIN Mo_Country R ON R.CountryID = H.ResidID
				LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
				LEFT JOIN Mo_State St ON St.StateID = S.StateID
				LEFT JOIN CRQ_WorldLang WL ON WL.WorldLanguageCodeID = S.BirthLangID
				LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
				LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
				LEFT JOIN Mo_Country CO ON CO.CountryID = H.cID_Pays_Origine
				LEFT JOIN tblCONV_PreferenceSuivi PS ON PS.iID_Preference_Suivi = S.iID_Preference_Suivi
				LEFT JOIN tblCONV_IdentiteSouscripteur IDS ON IDS.iID_Identite_Souscripteur = S.iID_Identite_Souscripteur
				WHERE S.SubscriberID = @SubscriberID

		IF @@ERROR <> 0
			SET @SubscriberID = -2
	END

	IF @SubscriberID > 0
	BEGIN
		-- Suppression des enregistements 200 non expédiés
		DELETE Un_CESP200
		WHERE HumanID = @SubscriberID
			AND tiType = 4
			AND iCESPSendFileID IS NULL

		IF @@ERROR <> 0
			SET @SubscriberID = -3
	END

	IF @SubscriberID > 0
	BEGIN
		-- Suppression du profil souscripteur s'il existe
		IF EXISTS
		(
			SELECT iID_Profil_Souscripteur
			FROM tblCONV_ProfilSouscripteur
			WHERE iID_Souscripteur = @SubscriberID
		)
		BEGIN
			EXECUTE @iCodeErr = dbo.DL_UN_SubscriberProfile @ConnectID, @SubscriberID
			IF @iCodeErr < 0
				SET @SubscriberID = -4
		END

		-- Suppression du souscripteur
		DELETE dbo.Un_Subscriber 
		WHERE SubscriberID = @SubscriberID

		IF @@ERROR <> 0
			SET @SubscriberID = -5
	END
	
	IF @SubscriberID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	-- Fin des traitements	
	RETURN @SubscriberID 
END


