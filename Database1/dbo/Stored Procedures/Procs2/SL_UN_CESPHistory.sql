/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESPHistory
Description         :	Historique de la PCEE d’une convention
Valeurs de retours  :
	Dataset :
		iCESP400ID				INTEGER			ID de l'enregistrement 400
		CotisationID			INTEGER			ID unique de la cotisation
		OperID					INTEGER			ID de l’opération
		OperDate				DATETIME		Date D’opération
		OperTypeID 				VARCHAR(3)		Type d’opération (Exemple : CPA, PRD, CHQ, etc.)
		EffectDate				DATETIME		Date effective de la cotisation, c’est la date de la transaction envoyé au PCEE.
		vcTransID				VARCHAR(15) 	ID unique qui est envoyé au PCEE pour identifier une transaction. 
		fCotisationFee			MONEY 			Montant d’épargne et de frais de l’enregistrement 400. 
		dtCESPSendFile			DATETIME 		Date d’envoi de l’enregistrement 400 au PCEE. 
		dtRead					DATETIME 		Date de réception de la réponse du PCEE à l’enregistrement 400. 
		fCESGPlanned 			MONEY			SCEE prévue.
		fCESGToReceive			MONEY			SCEE à recevoir.
		fCESGReceived			MONEY			SCEE reçue.
		fCESGToReimburse		MONEY			SCEE à rembourser.
		fCESGReimbursed		    MONEY			SCEE remboursée.
		fCESGPaid				MONEY			SCEE versée.
		fCESG					MONEY			SCEE.
		fACESGReceived			MONEY			SCEE + reçue.
		fACESGToReimburse		MONEY			SCEE + à rembourser.
		fACESGReimbursed		MONEY			SCEE + remboursée.
		fACESGPaid				MONEY			SCEE + versée.
		fACESG					MONEY			SCEE +.
		fCLBReceived			MONEY			BEC reçu.
		fCLBToReimburse		    MONEY			BEC à rembourser.
		fCLBReimbursed			MONEY			BEC remboursé.
		fCLBPaid				MONEY		    BEC versé.
		fCLB					MONEY		    BEC.
		vcCESP900CESGReason	    VARCHAR(200)	Raison SCEE.
		vcACESP900CESGReason	VARCHAR(200)	Raison SCEE +.
		siCESP800ErrorID		SMALLINT		Code de l’erreur retournée par le PCEE pour la transaction. (Ex : 7001, 7005, 
												etc.) Vide quand la transaction ne sera pas en erreur.
Note                :	
	ADX0001122	IA	2006-09-20	Bruno Lapointe		Création
	ADX0002233	BR	2007-01-03	Bruno Lapointe		SCEE prévue corrigée à 20% au lieu de 50%
	ADX0002281	BR	2007-02-07	Alain Quirion		Le cas des transfert de contrat n'était pas géré
	ADX0002426  BR	2007-05-08	Bruno Lapointe		Création de 900 pour PAE, TIN et OUT
	ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
	ADX0001201	UP	2007-07-31	Bruno Lapointe		Améliorer l'affichage des montants des TIN et OUT.
																Lors d'annulation financière gérer le négatif, utilier
																les 900 et prendre la date de réception des 900 s'il y
																en a une.
	ADX0003074	UR	2007-09-26	Bruno Lapointe		Date de reéception = Date de l'opération SUB.
	                2008-06-18  JJL                 Conversion sql-2005
					2008-07-03	Jean-Fronçois Arial	ajout d'une condition sur le ConventionID la jointure pour ne pas avoir toutes les conventions  
                    2008-10-17  Fatiha Araar  Ajouter les enregistrements 511
					2009-06-25	Patrick Robitaille	Ajout du champ iCESP900ID afin d'avoir l'ID de l'enregistrement 900 correspondant à ce 400
					2010-05-05	Pierre Paquet		Ne pas afficher les transactions de transfert à zéro (BEC).
					2010-10-14	Frederick Thibault	Ajout du champ Un_CESP400.fACESGPart pour régler le problème de remboursement SCEE+
					2013-06-04	Enlever les modification de "2010-05-05 Pierre Paquet" dans la clause where
***************************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPHistory] (

	@ConventionID INTEGER) -- ID de la convention
AS
BEGIN
	SELECT
		C4.iCESP400ID, -- ID de l'enregistrement 400
		CotisationID = ISNULL(Ct.CotisationID,O.OperID), -- ID unique de la cotisation
		O.OperID, -- ID de l’opération
		O.OperDate, -- Date D’opération
		O.OperTypeID, -- Type d’opération (Exemple : CPA, PRD, CHQ, etc.)
		EffectDate = ISNULL(Ct.EffectDate,O.OperDate), -- Date effective de la cotisation, c’est la date de la transaction envoyé au PCEE.
		C4.vcTransID, -- ID unique qui est envoyé au PCEE pour identifier une transaction. 

		fCotisationFee = 
			CASE 
				WHEN C4.iReversedCESP400ID IS NOT NULL 
					THEN -ISNULL(Ct.Cotisation + Ct.Fee, 0)
				WHEN ISNULL(C9.tiCESP900OriginID, 0) = 3 
					THEN -ISNULL(Ct.Cotisation + Ct.Fee, 0)
				ELSE 
					ISNULL(Ct.Cotisation + Ct.Fee, 0)
			END, -- Montant d’épargne et de frais de l’enregistrement 400. 

		S.dtCESPSendFile, -- Date d’envoi de l’enregistrement 400 au PCEE. 
		dtRead = OS.OperDate, -- Date de réception de la réponse du PCEE à l’enregistrement 400. 		

		fCESGPlanned = 
			CASE 
				WHEN C4.tiCESP400TypeID = 11 AND C4.iReversedCESP400ID IS NOT NULL 
					THEN -ROUND((Ct.Cotisation + Ct.Fee) * 0.2, 2)
				WHEN C4.tiCESP400TypeID = 11 
					THEN ROUND((Ct.Cotisation + Ct.Fee) * 0.2, 2)
				WHEN C4.tiCESP400TypeID = 21 
					THEN ISNULL(C4.fCESG, C9.fCESG + C9.fACESG)
				ELSE 0		--BR ADX0002281	
			END, -- SCEE prévue.

		fCESGToReceive = 
			CASE 
				WHEN C4.tiCESP400TypeID = 11 AND S.iCESPReceiveFileID IS NULL AND C4.iReversedCESP400ID IS NOT NULL 
					THEN -ISNULL(SUM(R9.fCESG), ROUND((Ct.Cotisation + Ct.Fee) * 0.2, 2))
				WHEN C4.tiCESP400TypeID = 11 AND S.iCESPReceiveFileID IS NULL 
					THEN ROUND(C4.fCotisation * 0.2, 2)
				ELSE 0
			END, -- SCEE à recevoir.
		
		fCESGReceived = 
			CASE 
				WHEN C4.tiCESP400TypeID = 19 AND C4.iReversedCESP400ID IS NOT NULL 
					THEN ISNULL(C9.fCESG, -ISNULL(CE.fCESG, 0))
				WHEN C4.tiCESP400TypeID = 19 
					THEN ISNULL(C9.fCESG, ISNULL(CE.fCESG, 0))
				WHEN C4.tiCESP400TypeID = 11 
					THEN ISNULL(C9.fCESG, 0)
				ELSE 0
			END, -- SCEE reçue.

		fCESGToReimburse = 
			CASE 
				WHEN C4.tiCESP400TypeID = 21 AND S.iCESPReceiveFileID IS NULL AND C4.iReversedCESP400ID IS NOT NULL 
					-- FT:
					-- On n'utilise plus la table 900 car les montants ne sont pas répartis sur 400-21
					--THEN ISNULL(SUM(R9.fCESG), -C4.fCESG)
					-- On prend la somme de tous les 400 renversés d'origine(déjà négatifs car remboursés), sinon (théoriquement improbable) le montant inverse du montant à être renversé.
					THEN ISNULL(SUM(R4.fCESG - R4.fACESGPart), -(C4.fCESG - C4.fACESGPart))
				WHEN C4.tiCESP400TypeID = 21 AND S.iCESPReceiveFileID IS NULL 
					-- Si pas un renversement on prend le montant SCEE de base et on l'inverse
					THEN -(C4.fCESG - C4.fACESGPart)
				ELSE 0
			END, -- SCEE à rembourser.

		fCESGReimbursed = 
			CASE 
				WHEN C4.tiCESP400TypeID = 21 
					-- FT:
					-- On n'utilise plus la table 900 uniquement, car les montants ne sont pas répartis sur 400-21
					--THEN -ISNULL(C9.fCESG,0)
					-- On inverse le montant de SCEE de base (négatif car remboursé, devient positif)
					THEN -ISNULL(C9.fCESG - C4.fACESGPart, 0)
				ELSE 0
			END, -- SCEE remboursée.

		fCESGPaid = 
			CASE 
				WHEN C4.tiCESP400TypeID IN (13, 23) AND C4.iReversedCESP400ID IS NOT NULL 
					THEN -ISNULL(C9.fCESG, -ISNULL(CE.fCESG, 0))
				WHEN C4.tiCESP400TypeID IN (13, 23) 
					THEN -ISNULL(C9.fCESG, ISNULL(CE.fCESG, 0))
				ELSE 0 --TEST
			END, -- SCEE versée.

		fCESG = 
			CASE 
				-- FT:
				-- On n'utilise plus la table 900 car les montants ne sont pas répartis sur 400-21
				WHEN C4.iReversedCESP400ID IS NOT NULL 
					--THEN ISNULL(C9.fCESG, -ISNULL(CE.fCESG, 0))
					THEN -ISNULL(CE.fCESG, 0)
				ELSE 
					--ISNULL(C9.fCESG, ISNULL(CE.fCESG, 0))
					ISNULL(CE.fCESG, 0)
			END,  -- SCEE.

		fACESGReceived = 
			CASE 
				WHEN C4.tiCESP400TypeID = 19 AND C4.iReversedCESP400ID IS NOT NULL 
					THEN ISNULL(C9.fACESG, -ISNULL(CE.fACESG, 0))
				WHEN C4.tiCESP400TypeID = 19 
					THEN ISNULL(C9.fACESG, ISNULL(CE.fACESG, 0))
				WHEN C4.tiCESP400TypeID = 11 
					THEN ISNULL(C9.fACESG,0)
				ELSE 0
			END, -- SCEE + reçue.

		fACESGToReimburse = 
			CASE 
				WHEN C4.tiCESP400TypeID = 21 AND S.iCESPReceiveFileID IS NULL AND C4.iReversedCESP400ID IS NOT NULL 
					-- FT:
					-- On n'utilise plus la table 900 car les montants ne sont pas répartis sur 400-21
					--THEN ISNULL(SUM(R9.fACESG), -C4.fACESGPart)
					-- On prend la somme de tous les 400 renversés d'origine(déjà négatifs car remboursés), sinon (théoriquement improbable) le montant inverse du montant à être renversé.
					THEN ISNULL(SUM(R4.fACESGPart), -(C4.fACESGPart))
				WHEN C4.tiCESP400TypeID = 21 AND S.iCESPReceiveFileID IS NULL 
					-- Si pas un renversement on prend le montant SCEE bonifié et on l'inverse
					THEN -C4.fACESGPart
				ELSE 0
			END, -- SCEE à rembourser.

		fACESGReimbursed = 
			CASE 
				WHEN C4.tiCESP400TypeID = 21 
					-- FT:
					-- On n'utilise plus la table 900 car les montants ne sont pas répartis sur 400-21
					--THEN -ISNULL(C9.fACESG, 0)
					-- On inverse le montant de SCEE bonifié (négatif car remboursé, devient positif)
					THEN -ISNULL(C4.fACESGPart, 0)
				ELSE 0
			END, -- SCEE + remboursée.
		
		fACESGPaid = 
			CASE 
				WHEN C4.tiCESP400TypeID IN (13,23) AND C4.iReversedCESP400ID IS NOT NULL 
					THEN -ISNULL(C9.fACESG, -ISNULL(CE.fACESG, 0))
				WHEN C4.tiCESP400TypeID IN (13,23) 
					THEN -ISNULL(C9.fACESG, ISNULL(CE.fACESG, 0))
				ELSE 0
			END, -- SCEE + versée.
		
		fACESG = 
			CASE 
				-- FT:
				-- On n'utilise plus la table 900 car les montants ne sont pas répartis sur 400-21
				WHEN C4.iReversedCESP400ID IS NOT NULL 
					--THEN ISNULL(C9.fACESG,-ISNULL(CE.fACESG,0))
					THEN -ISNULL(CE.fACESG, 0)
				ELSE 
					--ISNULL(C9.fACESG,ISNULL(CE.fACESG,0))
					ISNULL(CE.fACESG, 0)
			END,  -- SCEE +.

		fCLBReceived = 
			CASE 
				WHEN C4.tiCESP400TypeID = 19 AND C4.iReversedCESP400ID IS NOT NULL 
					THEN ISNULL(C9.fCLB, -ISNULL(CE.fCLB, 0))
				WHEN C4.tiCESP400TypeID = 19 
					THEN ISNULL(C9.fCLB, ISNULL(CE.fCLB, 0))
				WHEN C4.tiCESP400TypeID = 24 
					THEN ISNULL(C9.fCLB, 0)
				ELSE 0
			END, -- BEC reçu.
		
		fCLBToReimburse = 
			CASE 
				WHEN C4.tiCESP400TypeID = 21 AND S.iCESPReceiveFileID IS NULL AND C4.iReversedCESP400ID IS NOT NULL 
					THEN ISNULL(SUM(R9.fCLB), R4.fCLB)
				WHEN C4.tiCESP400TypeID = 21 AND S.iCESPReceiveFileID IS NULL 
					THEN -C4.fCLB
				ELSE 0
			END, -- BEC à rembourser.
		
		fCLBReimbursed = 
			CASE 
				WHEN C4.tiCESP400TypeID = 21 
					THEN -ISNULL(C9.fCLB, 0)
				ELSE 0
			END, -- BEC remboursé.
		
		fCLBPaid = 
			CASE 
				WHEN C4.tiCESP400TypeID IN (13, 23) AND C4.iReversedCESP400ID IS NOT NULL 
					THEN -ISNULL(C9.fCLB, -ISNULL(CE.fCLB, 0))
				WHEN C4.tiCESP400TypeID IN (13,23) 
					THEN -ISNULL(C9.fCLB, ISNULL(CE.fCLB, 0))
				ELSE 0
			END, -- BEC versé.
		
		fCLB = 
			CASE 
				WHEN C4.iReversedCESP400ID IS NOT NULL 
					THEN ISNULL(C9.fCLB, -ISNULL(CE.fCLB, 0))
				ELSE 
					ISNULL(C9.fCLB, ISNULL(CE.fCLB, 0))
			END,  -- BEC.
		
		iCESP900ID = ISNULL(C9.iCESP900ID, 0),
		C9R.vcCESP900CESGReason, -- Raison SCEE.
		C9AR.vcCESP900ACESGReason, -- Raison SCEE +.
		C8.siCESP800ErrorID, -- Code de l’erreur retournée par le PCEE pour la transaction. (Ex : 7001, 7005, etc.) Vide quand la transaction ne sera pas en erreur.
		
		bHaveNoCotisation = CAST (
									CASE 
										WHEN Ct.CotisationID IS NULL THEN 1
										ELSE 0
									END
							AS BIT)-- Indique s'il n'y pas de cotisation, donc seulement une opération.
	
	FROM Un_CESP400 C4
	JOIN Un_Oper O ON O.OperID = C4.OperID
	LEFT JOIN Un_Cotisation Ct ON Ct.CotisationID = C4.CotisationID
	LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
	LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C4.iCESPSendFileID
	LEFT JOIN Un_CESPReceiveFile R ON R.iCESPReceiveFileID = ISNULL(C9.iCESPReceiveFileID,S.iCESPReceiveFileID)
	LEFT JOIN Un_CESP900CESGReason C9R ON C9R.cCESP900CESGReasonID = C9.cCESP900CESGReasonID
	LEFT JOIN Un_CESP900ACESGReason C9AR ON C9AR.cCESP900ACESGReasonID = C9.cCESP900ACESGReasonID
	LEFT JOIN Un_CESP800 C8 ON C8.iCESP800ID = C4.iCESP800ID
	LEFT JOIN Un_CESP400 R4 ON R4.iCESP400ID = C4.iReversedCESP400ID
	LEFT JOIN Un_CESP900 R9 ON R9.iCESP400ID = R4.iCESP400ID
	LEFT JOIN Un_CESP CE ON (CE.OperID = O.OperID AND CE.ConventionID = C4.ConventionID) --JF Arial
	LEFT JOIN Un_Oper OS ON OS.OperID = R.OperID
	WHERE C4.ConventionID = @ConventionID
	--AND NOT (C4.tiCESP400TypeID = 19 AND C4.fCLB = 0 AND C4.fCESG = 0) -- 2010-05-05 Pierre Paquet
	--AND NOT (C4.tiCESP400TypeID = 23 AND C4.fCLB = 0 AND C4.fCESG = 0) -- 2010-05-05 Pierre Paquet
	
	GROUP BY 
		C4.iCESP400ID,
		C9.iCESP900ID,
		CE.iCESPID,
		Ct.CotisationID,
		O.OperID,
		O.OperDate,
		O.OperTypeID,
		Ct.EffectDate,
		C4.vcTransID,
		C4.iReversedCESP400ID,
		Ct.Cotisation,
		Ct.Fee,
		S.dtCESPSendFile,
		OS.OperDate,
		C4.tiCESP400TypeID,
		C4.fCESG,
		C4.fACESGPart,
		C4.fCLB,
		C9.fCESG,
		C9.fACESG,
		C9.fCLB,
		S.iCESPReceiveFileID,
		C4.fCotisation,
		CE.fCESG,
		CE.fACESG,
		CE.fCLB,
		C9R.vcCESP900CESGReason,
		C9AR.vcCESP900ACESGReason,
		C8.siCESP800ErrorID,
		R4.fCLB,
		C9.tiCESP900OriginID

------------
UNION ALL 
------------
--Ajouter l'historique des enregistrements 511
SELECT
       iCESP400ID = C511.iCESP511ID,  --ID de l'enregistrement 511
       CotisationID = C511.iOriginalCESP400ID, --ID de l'enregistrement 400 visé par le 511.
       OperID = 0,  -- ID de l’opération    
       OperDate = 0, --Date D’opération
       OperTypeID = '', --Type d’opération (Exemple : CPA, PRD, CHQ, etc.)
       EffectDate = 0, --Date effective de la cotisation, c’est la date de la transaction envoyé au PCEE.
       vcTransID = C511.vcTransID, --ID unique qui est envoyé au PCEE pour identifier une transaction.
       fCotisationFee = 0, --Montant d’épargne et de frais de l’enregistrement 511
       dtCESPSendFile = S.dtCESPSendFile, --Date d’envoi de l’enregistrement 511 au PCEE
	   dtRead = OS.OperDate, --Date de réception de la réponse du PCEE à l’enregistrement 511.
       fCESGPlanned = 0, --SCEE prévue.
	   fCESGToReceive = 0, --SCEE à recevoir.
	   fCESGReceived = 0, --SCEE reçue.
	   fCESGToReimburse	= 0, --SCEE à rembourser.
	   fCESGReimbursed	= 0, --SCEE remboursée.
	   fCESGPaid = 0, --SCEE versée.
	   fCESG = 0, --SCEE.
	   fACESGReceived = 0, --SCEE + reçue.
	   fACESGToReimburse = 0, --SCEE + à rembourser.
	   fACESGReimbursed	= 0, --SCEE + remboursée.
	   fACESGPaid = 0, --SCEE + versée.
	   fACESG = 0, --SCEE +.
	   fCLBReceived	= 0, --BEC reçu.
	   fCLBToReimburse = 0, --BEC à rembourser.
	   fCLBReimbursed = 0, --BEC remboursé.
	   fCLBPaid	= 0, --BEC versé.
	   fCLB	= 0, --BEC.
	   iCESP900ID = 0,	-- ID 900	
       vcCESP900CESGReason = '', --Raison Erreur SCEE.
       vcACESP900CESGReason = 'Modification aux infos du principal responsable',--Raison Erreur SCEE+.
	   siCESP800ErrorID = C8.siCESP800ErrorID, --Raison d'erreur 
       bHaveNoCotisation = CAST (1 AS bit) --Indique s'il n'y pas de cotisation, donc seulement une opération.

FROM UN_CESP511 C511
LEFT JOIN UN_CESP800 C8 ON C8.iCESP800ID = C511.iCESP800ID
LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C511.iCESPSendFileID
LEFT JOIN Un_CESPReceiveFile R ON R.iCESPReceiveFileID = S.iCESPReceiveFileID
LEFT JOIN Un_Oper OS ON OS.OperID = R.OperID
WHERE C511.ConventionID = @ConventionID
	---------
	UNION ALL
	---------
	SELECT 
		iCESP400ID = NULL, -- ID de l'enregistrement 400
		CotisationID = ISNULL(Ct.CotisationID,O.OperID), -- ID unique de la cotisation
		O.OperID, -- ID de l’opération
		O.OperDate, -- Date D’opération
		O.OperTypeID, -- Type d’opération (Exemple : CPA, PRD, CHQ, etc.)
		EffectDate = ISNULL(Ct.EffectDate,O.OperDate), -- Date effective de la cotisation, c’est la date de la transaction envoyé au PCEE.
		vcTransID = NULL, -- ID unique qui est envoyé au PCEE pour identifier une transaction. 
		fCotisationFee = Ct.Cotisation+Ct.Fee, -- Montant d’épargne et de frais de l’enregistrement 400. 
		dtCESPSendFile = NULL, -- Date d’envoi de l’enregistrement 400 au PCEE. 
		dtRead = NULL, -- Date de réception de la réponse du PCEE à l’enregistrement 400. 		
		fCESGPlanned = 0, -- SCEE prévue.
		fCESGToReceive = 0, -- SCEE à recevoir.
		fCESGReceived = 0, -- SCEE reçue.
		fCESGToReimburse = 0, -- SCEE à rembourser.
		fCESGReimbursed = 0, -- SCEE remboursée.
		fCESGPaid = 
			CASE 
				WHEN O.OperTypeID IN ('PAE','OUT') THEN -ISNULL(CE.fCESG,0)
			ELSE 0
			END, -- SCEE versée.
		fCESG = ISNULL(CE.fCESG,0), -- SCEE.
		fACESGReceived = 0, -- SCEE + reçue.
		fACESGToReimburse = 0, -- SCEE + à rembourser.
		fACESGReimbursed = 0, -- SCEE + remboursée.
		fACESGPaid = 
			CASE 
				WHEN O.OperTypeID IN ('PAE','OUT') THEN -ISNULL(CE.fACESG,0)
			ELSE 0
			END, -- SCEE + versée.
		fACESG = ISNULL(CE.fACESG,0), -- SCEE +.
		fCLBReceived = 0, -- BEC reçu.
		fCLBToReimburse = 0, -- BEC à rembourser.
		fCLBReimbursed = 0, -- BEC remboursé.
		fCLBPaid = 
			CASE 
				WHEN O.OperTypeID IN ('PAE','OUT') THEN -ISNULL(CE.fCLB,0)
			ELSE 0
			END, -- BEC versé.
		fCLB = ISNULL(CE.fCLB,0), -- BEC.
		iCESP900ID = 0,			  -- ID 900
		vcCESP900CESGReason = '', -- Raison SCEE.
		vcCESP900ACESGReason = '', -- Raison SCEE +.
		siCESP800ErrorID = '', -- Code de l’erreur retournée par le PCEE pour la transaction. (Ex : 7001, 7005, etc.) Vide quand la transaction ne sera pas en erreur.
		bHaveNoCotisation = 
			CAST (
				CASE 
					WHEN Ct.CotisationID IS NULL THEN 1
				ELSE 0
				END
				AS BIT)-- Indique s'il n'y pas de cotisation, donc seulement une opération.
	FROM Un_CESP CE
	JOIN Un_Oper O ON O.OperID = CE.OperID
	LEFT JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
	LEFT JOIN Un_CESP400 C4 ON C4.OperID = CE.OperID
	WHERE CE.ConventionID = @ConventionID
		AND O.OperTypeID IN ('TIN','PAE','OUT') 
		AND C4.iCESP400ID IS NULL
	ORDER BY 
		OperDate DESC,
		OperID DESC,
		ISNULL(Ct.EffectDate,O.OperDate) DESC,
		ISNULL(Ct.CotisationID,O.OperID) DESC,
		C4.iCESP400ID DESC,
		dtRead DESC

END
