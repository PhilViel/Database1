
/****************************************************************************************************
Code de service		:		fnPCEE_ValiderPresenceBEC
Nom du service		:		1.1.1 Valider la présence du BEC dans une convention
But					:		Vérifier si la convention possède un montant BEC ou si une demande de BEC a été envoyée pour cette convention
Facette				:		PCEE
Reférence			:		Document fnPCEE_ValiderPresenceBEC.DOCX

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
                        @iIDConvention				Identifiant unique de la convention			Oui

Exemples d'appel:
			SELECT [dbo].[fnPCEE_ValiderPresenceBEC](291551)		-- PAS DE BEC
			SELECT [dbo].[fnPCEE_ValiderPresenceBEC](291553)		-- AVEC UN BEC 

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						S/O							@bPresenceBEC								= 1 s'il y a présence de BEC dans la convention
																								= 0 s'il n'y a pas de de BEC dans la convention

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-06					Jean-François Gauthier					Création de la fonction
						2009-12-15					Jean-François Gauthier					Ajout de la validation pour l'enregistrement 400
																							ne soit pas renversé et est sans erreur
						2010-01-14					Jean-François Gauthier					Modification dans la détermination de l'état du BEC
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fnPCEE_ValiderPresenceBEC]
	(
		@iIDConvention INT
	)
RETURNS BIT 
AS
	BEGIN
		DECLARE 
			@bPresenceBEC			BIT
			,@dtDateDebutConvention	DATETIME
			,@iCESP400ID			INT

		DECLARE @tRepPCEE	TABLE
							(
								iCESPReceiveFileID		INT
								,cCESP900CESGReasonID	CHAR(1)
							)

		-- RECHERCHE DE LA DATE DE DÉBUT DE LA CONVENTION
		SELECT
			@dtDateDebutConvention = c.dtRegStartDate
		FROM
			dbo.Un_Convention c
		WHERE
			c.ConventionID = @iIDConvention

		-- INITIALISE LA VALEUR DE RETOUR À FAUX
		SET @bPresenceBEC = 0

		-- VÉRIFIER LA PRÉSENCE D'UN MONTANT BEC ASSOCIÉ À LA CONVENTION
		IF ISNULL((SELECT SUM(fnt.fCLB)FROM fntPCEE_ObtenirSubventionBons(@iIDConvention,@dtDateDebutConvention,GETDATE()) fnt),0) > 0 
			BEGIN
				SET @bPresenceBEC = 1
			END

		-- VÉFIFIER S'IL EXISTE UNE DEMANDE DE BEC ENVOYÉ
		-- 2009-12-15 JFG : ET QUE CETTE CETTE DEMANDE EST NON RENVERSÉE ET SANS ERREUR
		SELECT 
			TOP 1
				@iCESP400ID = u.iCESP400ID
		FROM 
			dbo.Un_CESP400 u 	
			LEFT OUTER JOIN dbo.Un_Convention c
				ON u.ConventionID = c.ConventionID			
		WHERE 
			u.ConventionID = @iIDConvention 
			AND 
			u.tiCESP400TypeID = 24 
			AND 
			u.iCESPSendFileID IS NOT NULL
			AND									
			u.iCESP800ID IS NULL	-- SANS ERREUR
			AND
			ISNULL(c.bCLBRequested,0) = 1		
			AND 
			NOT EXISTS (SELECT 1 FROM dbo.Un_CESP400 u2 WHERE u.iCESP400ID = u2.iReversedCESP400ID AND u2.iCESP800ID IS NULL)	-- NON RENVERSÉ
		ORDER BY
			u.iCESPSendFileID DESC	-- 2010-01-14 : ON DOIT PRENDRE La DERNIÈRE VALEUR REÇUE DU PCEE

		IF @iCESP400ID IS NOT NULL
			BEGIN
				-- RECHERCHE LES RÉPONSES REÇUES DU PCEE DANS UN_CESP900
				-- POUR LE DERNIER FICHIER REÇU (iCESPReceiveFileID)
				INSERT INTO @tRepPCEE
				(
					iCESPReceiveFileID
					,cCESP900CESGReasonID
				)
				SELECT
					u.iCESPReceiveFileID
					,u.cCESP900CESGReasonID
				FROM 
					dbo.Un_CESP900 u 
				WHERE 
					u.ConventionID = @iIDConvention 
					AND 
					u.iCESP400ID = @iCESP400ID 
					AND 
					u.iCESPReceiveFileID = (SELECT MAX(ce9.iCESPReceiveFileID) FROM dbo.Un_CESP900 ce9 WHERE ce9.iCESP400ID = @iCESP400ID AND ce9.ConventionID = @iIDConvention)
					
				-- UN SEUL ENREGISTREMENT ET QUE LA RAISON = 8, LE BEC EST ACTIF
				IF @@ROWCOUNT = 1 AND EXISTS(SELECT 1 FROM @tRepPCEE WHERE cCESP900CESGReasonID IN ('0','8'))
					BEGIN
						-- BEC EST PRÉSENT
						SET @bPresenceBEC = 1
					END
				ELSE	-- SI PLUS D'UN ENREGISTREMENT, LA RAISON 'C' NE DOIT PAS ÊTRE PRÉSENTE SI ON A UNE RAISON 8
					BEGIN
						IF @@ROWCOUNT > 1 AND EXISTS(SELECT 1 FROM @tRepPCEE WHERE cCESP900CESGReasonID IN ('0','8')) AND EXISTS(SELECT 1 FROM @tRepPCEE WHERE cCESP900CESGReasonID = 'C')
							BEGIN
								-- BEC N'EST PAS PRÉSENT
								SET @bPresenceBEC = 0
							END
						ELSE
							BEGIN
								-- BEC EST PRÉSENT
								SET @bPresenceBEC = 1
							END
					END
			END

		RETURN @bPresenceBEC
	END
