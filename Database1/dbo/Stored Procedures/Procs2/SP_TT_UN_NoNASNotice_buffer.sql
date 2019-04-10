 
/****************************************************************************************************
Code de service		:		SP_TT_UN_NoNASNotice
Nom du service		:		SP_TT_UN_NoNASNotice
But					:		Génère automatiquement les avis de convention sans NAS
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:
					
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
						S/O							RETURN 1 -- Pas d'erreur
													RETURN -1 -- Une erreur

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-06-08					Bruno Lapointe							Création point 10.27 : Avis de convention sans NAS
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
		2012-09-01					Donald Huppé							glpi 7338
EXEC SP_TT_UN_NoNASNotice_buffer
drop proc SP_TT_UN_NoNASNotice_buffer
 ****************************************************************************************************/

CREATE PROCEDURE dbo.SP_TT_UN_NoNASNotice_buffer
AS
BEGIN
	DECLARE 
		@MonthBeforeNoNASNotice INTEGER,
		@UserID INTEGER,
		@ConnectID INTEGER,
		@ConventionID INTEGER

	-- Va chercher l'identifiant unique de l'usager compurangers
	SELECT 
		@UserID = UserID
	FROM Mo_User
	WHERE LoginNameID = 'compurangers'

	-- Inscrit une connexion sur le serveur au nom de compurangers, cette connexion est nécessaire pour la création des documents
	INSERT INTO Mo_Connect (
		UserID,
		CodeID,
		ConnectStart,
		ConnectEnd,
		StationName)
	VALUES (
		@UserID,
		0,
		GETDATE(),
		GETDATE(),
		'SERVEUR')
 
		--	return
 
	IF @@ERROR = 0
	BEGIN
		SELECT @ConnectID = SCOPE_IDENTITY()

		-- Va chercher le paramètre qui dit après combien de mois les avis doivent être généré
		SELECT
			@MonthBeforeNoNASNotice = MonthBeforeNoNASNotice
		FROM Un_Def

		-- Va chercher la liste des conventions pour lesquelles il faut commander un avis de REEE sans NAS
		DECLARE UnAutoNoNASNotice CURSOR FOR
		
 		select ConventionID
		from (
			SELECT DISTINCT
				C.ConventionID,
				InForceDate = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)
			FROM dbo.Un_Convention C
			join (
				select 
					Cs.conventionid ,
					ccs.startdate,
					cs.ConventionStateID
				from 
					un_conventionconventionstate cs
					join (
						select 
						conventionid,
						startdate = max(startDate)
						from un_conventionconventionstate
						--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2011-10-31' -- Si je veux l'état à une date précise 
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID in (/*'REE',*/'TRA') -- je veux les convention qui ont cet état
				) css on C.conventionid = css.conventionid
			JOIN dbo.Mo_Human HS ON c.SubscriberID = HS.HumanID
			JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
			JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID AND U.SaleSourceID <> 235 -- Exclure Persevera
			
			LEFT JOIN (
					SELECT 
						d.DocGroup1,d.DocOrderTime,dt.DocTypeCode
					FROM CRQ_DocType dt
					join CRQ_DocTemplate dte ON dt.DocTypeID = dte.DocTypeID
					JOIN CRQ_Doc d ON d.DocTemplateID = dte.DocTemplateID
					WHERE dt.DocTypeCode IN ( 'NoNASNotice','SansNASSansForm','AvecNASSansForm')
				) doc on C.ConventionNo = doc.DocGroup1
			
			WHERE  (ISNULL(HS.SocialNumber, '') = '' OR ISNULL(HB.SocialNumber,'') = '')
			and doc.DocGroup1 is null -- n'a pas reçu la lettre
			)V
		WHERE 
			--DATEADD(MONTH, @MonthBeforeNoNASNotice, dbo.FN_CRQ_DateNoTime(V.InForceDate)) = dbo.FN_CRQ_DateNoTime(GETDATE())
			dbo.FN_CRQ_DateNoTime(V.InForceDate) < '2012-01-01'
			
		OPEN UnAutoNoNASNotice

		-- Ce positionne sur la première convention
      FETCH NEXT FROM UnAutoNoNASNotice
      INTO @ConventionID

		-- Boucle sur les conventions et commande un avis pour chacune d'eux
		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Commande un document
			EXEC SP_RP_UN_NoNASNotice @ConnectID, @ConventionID, 0

			-- Passe à la prochaine convention
		   FETCH NEXT FROM UnAutoNoNASNotice
		   INTO @ConventionID
		END

		CLOSE UnAutoNoNASNotice
		DEALLOCATE UnAutoNoNASNotice
	END
		
	IF @@ERROR = 0
		RETURN 1 -- Pas d'erreur
	ELSE
		RETURN -1 -- Une erreur
END


