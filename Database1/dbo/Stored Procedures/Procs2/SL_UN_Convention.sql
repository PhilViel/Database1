-- Stored Procedure


/***********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : SL_UN_Convention
Description         : Proc‚dure retournant les données d'une convention
Valeurs de retours  : >0  :	Tout à fonctionné

Exemple d'appel		: EXECUTE dbo.SL_UN_Convention 318389

select top 100 ConventionID from un_conventionOper where ConventionOperTypeID = 'MMQ'

Note                :							
					2004-04-29	Dominic Létourneau		Migration
					2004-04-30	Dominic Létourneau		10.23.1 (2.3) : Retrouve l'état actuel d'une 
														convention
					2004-05-21	Dominic Létourneau		09.18 (1.1) Ajout montant de prélèvement 
														automatique mensuel théorique
					2004-06-16	Bruno Lapointe			Point 13.10 : Montant total de subvention
	ADX0000525	BR	2004-06-21	Bruno Lapointe 
	ADX0000915	BR 2004-08-20	Bruno Lapointe			Ajout du champs texte du diplôme comme valeur 
														de retour.  
	ADX0000589	IA	2004-11-19	Bruno Lapointe			Ajout du champs de date du dernier dépôt pour
														contrat et relevés de dépôts
	ADX0000670	IA	2005-03-14	Bruno Lapointe			Ne plus retourner la date de dernier dépôt 
														pour relevés et contrats.
	ADX0000831	IA	2006-03-20	Bruno Lapointe			Adaptation des conventions pour PCEE 4.3
	ADX0001119	IA	2006-10-31	Alain Quirion			Ajout du champ fAvailableUnitQty
	ADX0002426	BR	2007-05-22	Alain Quirion			Modification : Un_CESP au lieu de Un_CESP900
	ADX0001355	IA	2007-06-06	Alain Quirion			Suppression de RegEndDateAddYear, Ajout de : dtRegEndDateAdjust, dtInforceDateTIN
					2008-09-15  Radu Trandafir			Ajout du champ DestinationRemboursement
														Ajout du champ DestinationRemboursementAutre
														Ajout du champ DateduProspectus	
														Ajout du champ SouscripteurDesireIQEE
														Ajout du champ LienCoSouscripteur
					2009-06-16	Patrick Robitaille		Ajout du champ bTuteur_Desire_Releve_Elect
					2009-08-11	Radu Trandafir			Ajout du champ iSous_Cat_ID_Resp_Prelevement
					2009-12-02	Jean-François Gauthier	Ajout du champ bFormulaireRecu
					2009-12-15	Jean-François Gauthier	Ajout des champs dtRegStartDate, bSouscripteur_Desire_IQEE,
														et des montants IQEE et IQEE+
					2010-03-17	Jean-François Gauthier	Utilisation de fntOPER_ObtenirOperationsCategorie pour récupérer
														les montants IQEE
					2010-11-16	Jean-Francois Arial		Ajout du champ bRISansPreuve pour le projet PCEE Phase 2
					2010-11-26	Pierre Paquet			Vérification de la clause 'remboursement intégral'.
					2011-10-28	Christian Chénard		Ajout du champ vcCommInstrSpec
					2011-11-08	Christian Chénard		Ajout du champ iID_Justification_Conv_Incomplete
					2012-02-22	Eric Michaud			Ajout de DateRQ,DateFinRegime,DateFinRegimeOriginale,DateEntreeVigueur
					2015-07-29	Steeve Picard			Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
					2016-05-04	Steeve Picard			Renommage de la fonction «fnIQEE_ObtenirDateEnregistrementRQ» qui était auparavant «fnIQEE_ObtenirDateDebutRegime»
                    2017-03-20  Steeve Bélanger         Ajout du champ tiMaximisationREEE
                    2017-06-16  Pierre-Luc Simard       Ne pas ajouter le champ tiMaximisationREEE pour l'instant suite à des problèmes avec les changements de bénéficiaire
                    2017-06-19  Steeve Picard           Remettre le champ tiMaximisationREEE
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Convention] (
	@ConventionID INTEGER) -- Identifiant unique de la convention	
AS
BEGIN
	-- Retourne les données nécessaires à l'objet TUnConvention
	SELECT
		C.SubscriberID,
		C.BeneficiaryID,
		C.ConventionNo,
		C.YearQualif,
        C.tiMaximisationREEE,
		PmtDate = C.FirstPmtDate,
		C.PmtTypeID,
		C.tiRelationshipTypeID,
		RT.vcRelationshipType,
		C.PlanID,
		C.GovernmentRegDate,
		C.ScholarshipYear,
		C.ScholarshipEntryID,
		P.PlanDesc,
		P.PlanTypeID,
		CA.BankID,
		CA.AccountName,
		CA.TransitNo,
		BankName = BC.CompanyName,
		B.BankTransit,
		BT.BankTypeCode,
		BT.BankTypeName,
		FirstPmtDate = ISNULL(Ct.EffectDate,0),
		ConventionBreaking = ISNULL(Bkg.ConventionID, 0),
		CapitalInterestAmount = ISNULL(CI.CapitalInterestAmount,0),
		GrantInterestAmount = ISNULL(CG.GrantInterestAmount,0),
		C.dtRegEndDateAdjust,
		C.dtInforceDateTIN,
		AvailableFeeAmount = ISNULL(CF.AvailableFeeAmount, 0),
		C.CoSubscriberID,
		CoSubscriberName = 
			CASE 
				WHEN ISNULL(C.CoSubscriberID, 0) = 0 THEN '' 
				WHEN H.IsCompany = 1 THEN H.LastName
			ELSE H.LastName + ', ' + H.FirstName 
			END,
		NbNSF = ISNULL(NSF.NbNSF,0),
		CESGInForceDate = ISNULL(GGI.InForceDate,0), -- #0768-07
		CS.ConventionStateID,
		CS.ConventionStateName,
		AutoMonthTheoricAmount = 
			CASE ISNULL(C.PmtTypeID, '') 
				WHEN 'AUT' THEN ISNULL(AMT.MonthTheoricAmount,0) 
			ELSE 0
			END, -- Valeur retournée seulement si paiement automatique
		DiplomaTextID = 9999, --C.DiplomaTextID,  -- ID unique du texte du diplôme
		DiplomaText = ISNULL(C.TexteDiplome, ''), -- Texte du diplôme   -- 2015-07-29
		C.bSendToCESP, -- Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).
		fCESG = ISNULL(GG.fCESG,0), -- Solde du compte de SCEE de la convention.
		fACESG = ISNULL(GG.fACESG,0), -- Solde du compte de SCEE+ de la convention.
		fCLB = ISNULL(GG.fCLB,0), -- Solde du compte de BEC de la convention.
		C.bCESGRequested, -- SCEE voulue (1) ou non (2)
		C.bACESGRequested, -- SCEE+ voulue (1) ou non (2)
		C.bCLBRequested, -- BEC voulu (1) ou non (2)
		C.tiCESPState, -- État de la convention au niveau des pr‚-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
		tiSubsCESPState = S.tiCESPState,
		tiCoSubsCESPState = Co.tiCESPState,
		tiBenefCESPState = Bf.tiCESPState,
		fAvailableUnitQty = ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0),
		DestinationRemboursementID=ISNULL(C.iID_Destinataire_Remboursement, 0), --L'ID du Destination remboursement
		DestinationRemboursementAutre=ISNULL(C.vcDestinataire_Remboursement_Autre, ''), --Destination remboursement autre
		DateduProspectus=ISNULL(C.dtDateProspectus, ''), --Date du prospectus
		SouscripteurDesireIQEE=ISNULL(C.bSouscripteur_Desire_IQEE, 0), --Souscripteur desire IQEE
		C.tiID_Lien_CoSouscripteur,
		LienCoSouscripteur=ISNULL(LC.vcRelationshipType,''),
		C.bTuteur_Desire_Releve_Elect,
		C.iSous_Cat_ID_Resp_Prelevement,
		C.bFormulaireRecu,	
		C.dtRegStartDate,
		C.bSouscripteur_Desire_IQEE,
		IQEE		=	ISNULL((SELECT SUM	(ISNULL(COP.ConventionOperAmount,0))
						FROM
							dbo.Un_ConventionOper COP
						WHERE
							COP.ConventionID = C.ConventionID
							AND 
							EXISTS
							(SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_CREDIT_BASE') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
		IQEEMaj		=	ISNULL((SELECT SUM	(ISNULL(COP.ConventionOperAmount,0))
						FROM
							dbo.Un_ConventionOper COP
						WHERE
							COP.ConventionID = C.ConventionID
							AND 
							EXISTS
							(SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_MAJORATION') f WHERE f.cID_Type_Oper_Convention = ISNULL(COP.ConventionOperTypeID,''))),0),
		bRISansPreuve = CAST(ISNULL(RI.bRISansPreuve , 0) AS BIT),
	--	C.vcCommInstrSpec,
	--	C.iID_Justification_Conv_Incomplete,
		DateRQ = dbo.fnIQEE_ObtenirDateEnregistrementRQ(C.ConventionID), 
  	    DateFinRegime = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'R', NULL), 
		DateFinRegimeOriginale = dbo.fnCONV_ObtenirDateFinRegime(C.ConventionID, 'T', NULL),
		DateEntreeVigueur = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)
	FROM 
		Un_Convention C
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID
		LEFT JOIN Un_RelationshipType LC ON LC.tiRelationshipTypeID = C.tiID_Lien_CoSouscripteur
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Un_Beneficiary Bf ON Bf.BeneficiaryID = C.BeneficiaryID	
		LEFT JOIN dbo.Un_Subscriber Co ON Co.SubscriberID = C.CoSubscriberID
		LEFT JOIN dbo.Mo_Human H ON H.HumanID = C.CoSubscriberID
		LEFT JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
		LEFT JOIN Mo_Bank B ON B.BankID = CA.BankID
		LEFT JOIN Mo_Company BC ON BC.CompanyID = B.BankID
		LEFT JOIN Mo_BankType BT ON BT.BankTypeID = B.BankTypeID
		LEFT JOIN (-- Retourne la plus petite date effective par convention
		SELECT 
			U.ConventionID,
			EffectDate = MIN(CT.EffectDate)
		FROM dbo.Un_Unit U
		JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
		WHERE U.ConventionID = @ConventionID
		GROUP BY U.ConventionID
		) CT ON C.ConventionID = CT.ConventionID
		LEFT JOIN (-- Retourne le total des intérêts sur montant souscrit par convention
			SELECT 
				ConventionID,
				CapitalInterestAmount = SUM(ISNULL(ConventionOperAmount,0))
			FROM Un_ConventionOper
			WHERE ConventionOperTypeID = 'INM'
			GROUP BY ConventionID
			) CI ON CI.ConventionID = C.ConventionID
		LEFT JOIN (-- Retourne le total des intérêts sur subvention par convention
			SELECT 
				ConventionID,
				GrantInterestAmount = SUM(ISNULL(ConventionOperAmount,0))
			FROM Un_ConventionOper
			WHERE ConventionOperTypeID = 'INS'
			GROUP BY ConventionID
			) CG ON CG.ConventionID = C.ConventionID
		LEFT JOIN (-- Retourne le total des frais disponibles par convention
			SELECT 
				ConventionID,
				AvailableFeeAmount = SUM(ISNULL(ConventionOperAmount,0))
			FROM Un_ConventionOper
			WHERE ConventionOperTypeID = 'FDI'
			GROUP BY ConventionID
			) CF ON CF.ConventionID = C.ConventionID
		LEFT JOIN (-- Retourne les conventions en arrêt de paiement
			SELECT DISTINCT ConventionID
			FROM Un_Breaking
			WHERE ISNULL(BreakingEndDate,0) <= 0
				OR (BreakingStartDate > = GETDATE()	AND BreakingEndDate < = GETDATE())
			) BKG ON BKG.ConventionID = C.ConventionID
		LEFT JOIN (-- Retourne le nombre de nsf par convention
			SELECT
				U.ConventionID,
				NbNSF = COUNT(DISTINCT O.OperID)
			FROM Mo_BankReturnLink R
			JOIN Un_Oper O ON O.OperID = R.BankReturnCodeID
			JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			WHERE R.BankReturnTypeID = '901'
				AND U.ConventionID = @ConventionID
			GROUP BY U.ConventionID
			) NSF ON NSF.ConventionID = C.ConventionID
		LEFT JOIN (-- Date de vigueur enregistrée à la SCÉÉ #0768-07
			SELECT
				G1.ConventionID,
				InForceDate = G1.dtTransaction 
			FROM Un_CESP100 G1
			LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G1.iCESPSendFileID
			JOIN (-- Retourne la plus grande date d'envoi de fichier scee par convention
				SELECT 
					G1.ConventionID,
					dtCESPSendFile = MAX(ISNULL(S.dtCESPSendFile, GETDATE()))
				FROM Un_CESP100 G1
				LEFT JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G1.iCESPSendFileID
				GROUP BY G1.ConventionID
				) V ON V.ConventionID = G1.ConventionID AND ISNULL(S.dtCESPSendFile, GETDATE()) = V.dtCESPSendFile
			) GGI ON GGI.ConventionID = C.ConventionID
		LEFT JOIN (-- 10.23.1 (2.3) : Retrouve l'état actuel d'une convention
			SELECT 
				T.ConventionID,
				CS.ConventionStateID,
				CS.ConventionStateName
			FROM (-- Retourne la plus grande date de début d'un état par convention
				SELECT 
					ConventionID,
					MaxDate = MAX(StartDate)
				FROM Un_ConventionConventionState
				WHERE ConventionID = @ConventionID
					AND StartDate <= GETDATE()
				GROUP BY ConventionID
				) T
			JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
			) CS ON C.ConventionID = CS.ConventionID
		LEFT JOIN (-- 09.18 (1.1) Ajout montant de prélèvement automatique mensuel théorique sur convention
			SELECT
				U.ConventionID,
				MonthTheoricAmount = 
					SUM(
						ROUND(M.PmtRate * U.UnitQty,2) + -- Cotisation et frais
						dbo.FN_CRQ_TaxRounding
							((	CASE U.WantSubscriberInsurance -- Assurance souscripteur
									WHEN 0 THEN 0
								ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
								END +
								ISNULL(BI.BenefInsurRate,0)) * -- Assurance bénéficiaire
							(1+ISNULL(St.StateTaxPct,0)))) -- Taxes
			FROM dbo.Un_Unit U
			JOIN Un_Modal M ON U.ModalID = M.ModalID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
			LEFT JOIN Mo_State St ON St.StateID = S.StateID
			LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
			LEFT JOIN (
				SELECT
					U.UnitID,
					CotisationFee = SUM(Ct.Fee+Ct.Cotisation)
				FROM dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
				WHERE U.ConventionID = @ConventionID
				GROUP BY U.UnitID
				) Ct ON U.UnitID = Ct.UnitID
			WHERE M.PmtByYearID = 12
			  AND ISNULL(Ct.CotisationFee,0) < M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2)
			GROUP BY U.ConventionID
			) AMT ON C.ConventionID = AMT.ConventionID 
		LEFT JOIN (
			SELECT 
				ConventionID,
				fCESG = SUM(fCESG),
				fACESG = SUM(fACESG),
				fCLB = SUM(fCLB)
			FROM Un_CESP
			GROUP BY ConventionID
			) GG ON GG.ConventionID = C.ConventionID
		--LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID		-- 2015-07-29
		LEFT JOIN ( -- Unité résiliés
				SELECT 
					U.ConventionID, 
					UnitRes = SUM(UR.UnitQty)
				FROM Un_UnitReduction UR
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
				WHERE U.ConventionID = @ConventionID
				GROUP BY U.ConventionID) SR ON SR.ConventionID = C.ConventionID
		LEFT JOIN ( -- Unité utilisés
				SELECT 
					U.ConventionID, 
					UnitUse = SUM(A.fUnitQtyUse)
				FROM Un_UnitReduction UR
				JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID		
				WHERE U.ConventionID = @ConventionID
				GROUP BY U.ConventionID) SU ON SU.ConventionID = C.ConventionID
	/*	LEFT JOIN ( -- RI sans preuve
				SELECT U.ConventionID, 1 AS bRISansPreuve 
				FROM dbo.Un_Unit U 
				--INNER JOIN dbo.Un_Convention C ON U . ConventionID = C . ConventionID 
				WHERE U. IntReimbDate IS NOT NULL 
				AND EXISTS ( SELECT 1 -- Il existe une transaction de remboursement. 
								FROM UN_CESP400 C4 
								WHERE U.ConventionID = C4.ConventionID AND C4.tiCESP400TypeID = 21 
								AND iCESP800ID IS NULL)  
				AND NOT EXISTS ( SELECT 1 -- Il n'existe pas de paiement aux études. 
									FROM UN_CESP400 C4 
									WHERE U.ConventionID = C4.ConventionID AND C4.tiCESP400TypeID = 14 
									AND iCESP800ID IS NULL)) RI ON (RI.ConventionID = C.ConventionID)	
	*/
		LEFT JOIN ( -- RI sans preuve
				SELECT U.ConventionID, 1 AS bRISansPreuve 
				FROM dbo.Un_Unit U	
					inner join un_intReimb IR ON IR.unitid = U.unitid
				WHERE IR.CESGRenonciation = 1 
				) RI ON (RI.ConventionID = C.ConventionID)			
	WHERE 
		C.ConventionID = @ConventionID
END