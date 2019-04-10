/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESPSendFileDetails
Description         :	Retourne le détail d’un fichier d’envoi au PCEE.
Valeurs de retours  :	Dataset :
									vcTransacType			VARCHAR(75)	Type de transaction (100, 200, etc.) ainsi que sa description.
									bCountEnabled			BIT			Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
									iCount					INTEGER		Nombre de transaction de ce type.
									bCotisationEnabled	BIT			Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
									fCotisation				MONEY			Montant de cotisation.
									bCESGEnabled			BIT			Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
									fCESG					MONEY			Montant de SCEE.
									bACESGEnabled			BIT			Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
									fACESG					MONEY			Montant de SCEE+.
									bCLBEnabled				BIT			Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
									fCLB					MONEY			Montant de BEC.
Note                :	ADX0000811	IA	2006-04-12	Bruno Lapointe		Création
				ADX0002426	BR	2007-05-23	Bruno Lapointe				Gestion de la table Un_CESP.
                    :			2008-10-16  Fatiha Araar				Calculer le nombre d'enregistrement 511
								2010-10-14	Frederick Thibault			Ajout du champ fACESGPart pour régler le problème de remboursement SCEE+
								2011-06-03	Frederick Thibault			Enlevé la table Un_CESP de la requete pour les transaction 400 (autre que 11)
                                                
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPSendFileDetails] (
	@iCESPSendFileID INTEGER ) -- ID du fichier d’envoi au PCEE.
AS
BEGIN
	SELECT
		iID = 1,
		vcTransacType = '100 - Conventions', -- Type de transaction (100, 200, etc.) ainsi que sa description.
		bCountEnabled = CAST(1 AS BIT), -- Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
		iCount = COUNT(iCESP100ID), -- Nombre de transaction de ce type.
		bCotisationEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
		fCotisation = 0, -- Montant de cotisation.
		bCESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
		fCESG = 0, -- Montant de SCEE.
		bACESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
		fACESG = 0, -- Montant de SCEE+.
		bCLBEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
		fCLB = 0 -- Montant de BEC.
	FROM Un_CESP100
	WHERE iCESPSendFileID = @iCESPSendFileID
	---------
	UNION ALL
	---------
	SELECT
		iID = 2,
		vcTransacType = '200', -- Type de transaction (100, 200, etc.) ainsi que sa description.
		bCountEnabled = CAST(0 AS BIT), -- Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
		iCount = 0, -- Nombre de transaction de ce type.
		bCotisationEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
		fCotisation = 0, -- Montant de cotisation.
		bCESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
		fCESG = 0, -- Montant de SCEE.
		bACESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
		fACESG = 0, -- Montant de SCEE+.
		bCLBEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
		fCLB = 0 -- Montant de BEC.
	---------
	UNION ALL
	---------
	SELECT
		iID = tiType,
		vcTransacType = 
			CASE tiType	
				WHEN 3 THEN '  3 - Bénéficiaire'
				WHEN 4 THEN ' 4 - Souscripteur'
			END, -- Type de transaction (100, 200, etc.) ainsi que sa description.
		bCountEnabled = CAST(1 AS BIT), -- Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
		iCount = COUNT(iCESP200ID), -- Nombre de transaction de ce type.
		bCotisationEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
		fCotisation = 0, -- Montant de cotisation.
		bCESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
		fCESG = 0, -- Montant de SCEE.
		bACESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
		fACESG = 0, -- Montant de SCEE+.
		bCLBEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
		fCLB = 0 -- Montant de BEC.
	FROM Un_CESP200
	WHERE iCESPSendFileID = @iCESPSendFileID
	GROUP BY tiType
	---------
	UNION ALL
	---------
	SELECT
		iID = 5,
		vcTransacType = '400 - Transactions', -- Type de transaction (100, 200, etc.) ainsi que sa description.
		bCountEnabled = CAST(0 AS BIT), -- Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
		iCount = 0, -- Nombre de transaction de ce type.
		bCotisationEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
		fCotisation = 0, -- Montant de cotisation.
		bCESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
		fCESG = 0, -- Montant de SCEE.
		bACESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
		fACESG = 0, -- Montant de SCEE+.
		bCLBEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
		fCLB = 0 -- Montant de BEC.
	---------
	UNION ALL
	---------
	SELECT
		iID = 6,
		vcTransacType = ' 11 - Cotisations', -- Type de transaction (100, 200, etc.) ainsi que sa description.
		bCountEnabled = CAST(0 AS BIT), -- Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
		iCount = 0, -- Nombre de transaction de ce type.
		bCotisationEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
		fCotisation = 0, -- Montant de cotisation.
		bCESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
		fCESG = 0, -- Montant de SCEE.
		bACESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
		fACESG = 0, -- Montant de SCEE+.
		bCLBEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
		fCLB = 0 -- Montant de BEC.
	---------
	UNION ALL
	---------
	SELECT
		iID = 
			CASE 
				WHEN C.bCESGRequested <> 0 AND C.bACESGRequested <> 0 THEN 7
				WHEN C.bCESGRequested <> 0 AND C.bACESGRequested = 0 THEN 8
			ELSE 9
			END,
		vcTransacType =
			CASE 
				WHEN C.bCESGRequested <> 0 AND C.bACESGRequested <> 0 THEN '   SCEE et SCEE+ voulues (*)'
				WHEN C.bCESGRequested <> 0 AND C.bACESGRequested = 0 THEN '   SCEE voulue seulement (*)'
			ELSE '   SCEE et SCEE+ non voulues (*)'
			END, -- Type de transaction (100, 200, etc.) ainsi que sa description.
		bCountEnabled = CAST(1 AS BIT), -- Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
		iCount = COUNT(G4.iCESP400ID), -- Nombre de transaction de ce type.
		bCotisationEnabled = CAST(1 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
		fCotisation = SUM(G4.fCotisation), -- Montant de cotisation.
		bCESGEnabled = C.bCESGRequested, -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
		fCESG = 
			CASE
				WHEN C.bCESGRequested = 0 THEN 0
			ELSE SUM(ROUND(G4.fCotisation*.2,2))
			END, -- Montant de SCEE.
		bACESGEnabled = C.bACESGRequested, -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
		fACESG = 
			CASE
				WHEN C.bACESGRequested = 0 THEN 0
			ELSE SUM(ROUND(G4.fCotisation*.1,2))
			END, -- Montant de SCEE+.
		bCLBEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
		fCLB = 0 -- Montant de BEC.
	FROM Un_CESP400 G4
	JOIN dbo.Un_Convention C ON C.ConventionID = G4.ConventionID
	WHERE G4.iCESPSendFileID = @iCESPSendFileID
		AND G4.tiCESP400TypeID = 11 -- Cotisations
	GROUP BY 
		C.bCESGRequested, 
		C.bACESGRequested
	---------
	UNION ALL
	---------
	SELECT
		iID = G4.tiCESP400TypeID,
		vcTransacType = ' '+CAST(G4.tiCESP400TypeID AS VARCHAR(3))+' - '+G4T.vcCESP400Type, -- Type de transaction (100, 200, etc.) ainsi que sa description.
		bCountEnabled = CAST(1 AS BIT), -- Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
		iCount = COUNT(G4.iCESP400ID), -- Nombre de transaction de ce type.
		bCotisationEnabled = 
			CAST(	CASE 
						WHEN G4.tiCESP400TypeID IN (22,24) THEN 0
					ELSE 1
					END AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
		fCotisation = SUM(G4.fCotisation), -- Montant de cotisation.
		bCESGEnabled = 
			CAST(	CASE 
						WHEN G4.tiCESP400TypeID IN (14,24) THEN 0
					ELSE 1
					END AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
		fCESG = 
			CASE 
				-- FT1
				--WHEN G4.tiCESP400TypeID IN (19,23) THEN SUM(ISNULL(CE.fCESG,G4.fCESG))
				WHEN G4.tiCESP400TypeID IN (19,23) THEN SUM(G4.fCESG)
			ELSE SUM(G4.fCESG)
			END, -- Montant de SCEE.
		bACESGEnabled = 
			CAST(	CASE 
						WHEN G4.tiCESP400TypeID IN (14,24) THEN 0
					ELSE 1
					END AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
		fACESG = 
			CASE 
				-- FT1
				--WHEN G4.tiCESP400TypeID IN (19,23) THEN SUM(ISNULL(CE.fACESG,0)) FT (2010-11-01)
				WHEN G4.tiCESP400TypeID IN (19,23) THEN SUM(G4.fACESGPart)
			ELSE 0
			END, -- Montant de SCEE+.
		bCLBEnabled = 
			CAST(	CASE 
						WHEN G4.tiCESP400TypeID = 14 THEN 0
					ELSE 1
					END AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
		fCLB = 
			CASE 
				WHEN G4.tiCESP400TypeID = 24 THEN 100
				-- FT1
				--WHEN G4.tiCESP400TypeID IN (19,23) THEN SUM(ISNULL(CE.fCLB,G4.fCLB))
				WHEN G4.tiCESP400TypeID IN (19,23) THEN SUM(G4.fCLB)
			ELSE SUM(G4.fCLB)
			END -- Montant de BEC.
	FROM Un_CESP400 G4
	JOIN Un_CESP400Type G4T ON G4T.tiCESP400TypeID = G4.tiCESP400TypeID
	JOIN dbo.Un_Convention C ON C.ConventionID = G4.ConventionID
	-- FT1
	--LEFT JOIN Un_CESP CE ON CE.OperID = G4.OperID AND G4.tiCESP400TypeID IN (19,23)
	WHERE G4.iCESPSendFileID = @iCESPSendFileID
		AND G4.tiCESP400TypeID <> 11 -- Cotisations
	GROUP BY 
		G4.tiCESP400TypeID,
		G4T.vcCESP400Type

	 ---------
	UNION ALL
	---------
--Calculer le nombre d'enregistrement 511
SELECT
		iID = 511,
		vcTransacType = '511 - 12 - Modifications au prinicipal responsable', -- Type de transaction (511) ainsi que sa description.
		bCountEnabled = CAST(1 AS BIT), -- Indique si on doit laisser vide la colonne nombre ou y inscrire la valeur de iCount
		iCount = COUNT(iCESP511ID), -- Nombre de transaction de ce type.
		bCotisationEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne cotisation.
		fCotisation = 0, -- Montant de cotisation.
		bCESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE.
		fCESG = 0, -- Montant de SCEE.
		bACESGEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne SCEE+.
		fACESG = 0, -- Montant de SCEE+.
		bCLBEnabled = CAST(0 AS BIT), -- Indique si on doit mettre un ‘-‘ ou le montant dans la colonne BEC.
		fCLB = 0 -- Montant de BEC.
	FROM Un_CESP511
   WHERE iCESPSendFileID = @iCESPSendFileID
ORDER BY iID
END


