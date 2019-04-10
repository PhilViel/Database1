/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_RetransfertIQEEsurTIO
Nom du service		: Retransférer l'IQÉÉ suite à une opération TIO
But 				: Mesure temporaire qui a pour objectif de déplacer les montants d'IQÉÉ avec les opération TIO afin
					  que les relevés de dépôts reflète plus la réalité en attendant l'analyse d'une mesure permanente
					  pour les transferts de l'IQÉÉ.
Facette				: IQÉÉ

Historique des modifications:
        Date			Programmeur							Description									Référence
        ------------	----------------------------------	-----------------------------------------	------------
        2011-02-21		Éric Deshaies						Création du service
        2011-04-15		Éric Deshaies						Empêcher la mesure temporaire d'appliquer
												            le transfert d'IQÉÉ dans une transaction
												            du passé sans en informer les finances.
												            Ne pas transferérer l’IQÉÉ reçu entre la 
												            date d’importation et la date de dépôt.
        2016-11-25  Steeve Picard               Changement d'orientation de la valeur de retour de «fnIQEE_RemplacementBeneficiaireReconnu»
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RetransfertIQEEsurTIO]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @dtDate_Essais_Transfert DATETIME,
			@iID_IQEE_OUT INT,
			@iID_Convention INT,
			@iID_Convention_Courant INT,
			@vcNo_Convention VARCHAR(15),
			@iID_Convention_Dest INT,
			@vcNo_Convention_Dest VARCHAR(15),
			@iID_TIO INT,
			@iID_Operation_Out INT,
			@iID_Operation_TFR INT,
			@iID_Operation_TIN INT,
			@iID_Cotisation_Out INT,
			@mSolde_CBQ_Avant MONEY,
			@mSolde_MMQ_Avant MONEY,
			@mSolde_MIM_Avant MONEY,
			@mSolde_ICQ_Avant MONEY,
			@mSolde_IMQ_Avant MONEY,
			@mSolde_IIQ_Avant MONEY,
			@mSolde_III_Avant MONEY,
			@mSolde_IQI_Avant MONEY,
			@mMontant_Total_Transfert MONEY,
			@mMontant_Total_BEC_Rend_BEC MONEY,
			@mMontant_BEC MONEY,
			@mMontant_JVM MONEY,
			@fPourcentage_Transfert FLOAT,
			@mTransfert_CBQ MONEY,
			@mTransfert_MMQ MONEY,
			@mTransfert_MIM MONEY,
			@mTransfert_ICQ MONEY,
			@mTransfert_IMQ MONEY,
			@mTransfert_IIQ MONEY,
			@mTransfert_III MONEY,
			@mTransfert_IQI MONEY,
			@mSolde_CBQ_Apres MONEY,
			@mSolde_MMQ_Apres MONEY,
			@mSolde_MIM_Apres MONEY,
			@mSolde_ICQ_Apres MONEY,
			@mSolde_IMQ_Apres MONEY,
			@mSolde_IIQ_Apres MONEY,
			@mSolde_III_Apres MONEY,
			@mSolde_IQI_Apres MONEY,
			@dtDate_Barrure_Operation DATETIME,
			@bTransfert_a_0 BIT,
			@bPresence_Transfert_BEC BIT,
			@bAutres_raisons BIT,
			@bPresence_Transfert_BEC_Avec_Rendement_BEC BIT,
			@bAdmissible_Transfert_IQEE BIT

	SET @dtDate_Essais_Transfert = GETDATE()

	SET XACT_ABORT ON 

	BEGIN TRANSACTION

	BEGIN TRY
		-- Retenir la date de barrure des opérations et la remplacer par une plus ancienne date.  Elle sera remise en place à
		-- la fin du traitement.
		SELECT TOP 1 @dtDate_Barrure_Operation = D.LastVerifDate
		FROM Un_Def D

		UPDATE Un_Def
		SET LastVerifDate = '2007-02-21'  -- Date de début de l'IQÉÉ

		--------------------------------------------------------------------------------------------
		-- Construire une liste des transferts admissibles et non admissibles à la mesure temporaire
		--------------------------------------------------------------------------------------------
		INSERT INTO tblTEMP_InformationsIQEEPourOUT
			(dtDate_Essais_Transfert,iID_Convention,vcNo_Convention,iID_TIO,iID_Operation_Out,iID_Operation_TFR,iID_Operation_TIN,iID_Cotisation_Out,iID_Convention_Dest,vcNo_Convention_Dest)
		SELECT DISTINCT @dtDate_Essais_Transfert,C.ConventionID,C.ConventionNo,TIO.iTIOID,TIO.iOUTOperID,TIO.iTFROperID,TIO.iTINOperID,COC.CotisationID,C2.ConventionID,C2.ConventionNo
		FROM Un_Oper O
			 LEFT JOIN Un_TIO TIO ON TIO.iOUTOperID = O.OperID
			 LEFT JOIN Un_OperCancelation OC1 ON OC1.OperID = O.OperID
			 LEFT JOIN Un_OperCancelation OC2 ON OC2.OperSourceID = O.OperID
			 LEFT JOIN Un_ConventionOper COA ON COA.OperID = O.OperID
			 LEFT JOIN Un_CESP COB ON COB.OperID = O.OperID
			 LEFT JOIN Un_Cotisation COC ON COC.OperID = O.OperID
			 LEFT JOIN dbo.Un_Unit U ON U.UnitID = COC.UnitID
			 LEFT JOIN dbo.Un_Convention C ON C.ConventionID = COALESCE(U.ConventionID,COA.ConventionID,COB.ConventionID)
			 LEFT JOIN Un_Oper O2 ON O2.OperID = iTINOperID
			 LEFT JOIN Un_ConventionOper COA2 ON COA2.OperID = O2.OperID
			 LEFT JOIN Un_CESP COB2 ON COB2.OperID = O2.OperID
			 LEFT JOIN Un_Cotisation COC2 ON COC2.OperID = O2.OperID
			 LEFT JOIN dbo.Un_Unit U2 ON U2.UnitID = COC2.UnitID
			 LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = COALESCE(U2.ConventionID,COA2.ConventionID,COB2.ConventionID)
		WHERE O.dtSequence_Operation >= '2008-08-29 00:00:00.000'
-- Temporairement empêcher la mesure temporaire d'appliquer le transfert d'IQÉÉ dans une transaction du passé sans en informer les finances
		  AND O.dtSequence_Operation >= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
		  -- Transfert OUT
		  AND O.OperTypeID = 'OUT'
		  -- Pas une annulation
		  AND OC1.OperID IS NULL
		  -- Pas annulée
		  AND OC2.OperSourceID IS NULL
		ORDER BY C.ConventionNo

		UPDATE T
		SET bPas_TIO = CASE WHEN T.iID_TIO IS NULL THEN 1 ELSE NULL END
		FROM tblTEMP_InformationsIQEEPourOUT T
		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bConvention_OUT_pas_fermee = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_ConventionConventionState CS ON CS.ConventionID = T.iID_Convention 
												 AND CS.StartDate = (SELECT MAX(CS2.StartDate)
																	 FROM Un_ConventionConventionState CS2
																	 WHERE CS2.ConventionID = T.iID_Convention
																	   AND CS2.StartDate <= GETDATE())
												 AND CS.ConventionStateID <> 'FRM'
		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bOUT_Deplace_deja_IQEE = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
		WHERE EXISTS(SELECT *
					 FROM Un_ConventionOper CO2
					 WHERE CO2.OperID = T.iID_Operation_Out
					   AND CO2.ConventionOperTypeID IN ('CBQ','MMQ','MIM','ICQ','IMQ','IIQ','III','IQI'))
		  AND T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bAucun_Solde_IQEE_ou_Rendements = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_Oper O ON O.OperID = T.iID_Operation_Out
		WHERE 0 = (SELECT ISNULL(SUM(CO2.ConventionOperAmount),0)
				   FROM Un_ConventionOper CO2
						JOIN Un_Oper O2 ON O2.OperID = CO2.OperID
									   AND (O2.dtSequence_Operation < O.dtSequence_Operation OR
											(O2.dtSequence_Operation = O.dtSequence_Operation AND O2.OperID < O.OperID))
				   WHERE CO2.ConventionID = T.iID_Convention
					 AND CO2.ConventionOperTypeID IN ('CBQ','MMQ','MIM','ICQ','IMQ','IIQ','III','IQI'))
		  AND T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bAutre_sortie_IQEE_apres_transfert = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_Oper O ON O.OperID = T.iID_Operation_Out
		WHERE EXISTS (SELECT *
					  FROM Un_ConventionOper CO2
						   JOIN Un_Oper O2 ON O2.OperID = CO2.OperID
										  AND O2.dtSequence_Operation > O.dtSequence_Operation
										  AND O2.OperTypeID IN ('IQE','OUT','PAE','RIO')
					  WHERE CO2.ConventionID = T.iID_Convention
						AND CO2.ConventionOperTypeID IN ('CBQ','MMQ')
						AND CO2.ConventionOperAmount < 0)
		  AND T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bCompte_en_perte = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_Oper O ON O.OperID = T.iID_Operation_Out
		WHERE EXISTS (SELECT CO.ConventionOperTypeID,SUM(CO.ConventionOperAmount)
					  FROM Un_ConventionOper CO
					  WHERE CO.ConventionID = T.iID_Convention
						AND CO.ConventionOperTypeID IN ('CBQ','MMQ','MIM','ICQ','IMQ','IIQ','III','IQI')
					  GROUP BY CO.ConventionOperTypeID
					  HAVING SUM(CO.ConventionOperAmount) < 0)
		  AND T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bChangement_Benef_non_reconnu_avant_transfert = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_Oper O ON O.OperID = T.iID_Operation_Out
		WHERE EXISTS (SELECT *
					  FROM [dbo].[fntCONV_RechercherChangementsBeneficiaire](NULL,NULL,T.iID_Convention,NULL,'2008-08-29 00:00:00.000',O.dtSequence_Operation,NULL,NULL,NULL,NULL,NULL,NULL,NULL) CB
					  WHERE CB.vcCode_Raison <> 'INI'
						AND [dbo].[fnIQEE_RemplacementBeneficiaireReconnu](CB.iID_Changement_Beneficiaire,NULL,NULL,NULL,NULL,NULL,NULL) = 0)
		  AND T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bTransfert_non_reconnu_avant_transfert = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_Oper O ON O.OperID = T.iID_Operation_Out
		WHERE EXISTS(SELECT *
					 FROM Un_Oper VO
						  LEFT JOIN Un_OperCancelation VOC1 ON VOC1.OperSourceID = VO.OperID
						  LEFT JOIN Un_OperCancelation VOC2 ON VOC2.OperID = VO.OperID
						  JOIN Un_OUT VTOU ON VTOU.OperID = VO.OperID
										  AND (VTOU.tiBnfRelationWithOtherConvBnf = 3 OR VTOU.bOtherContratBnfAreBrothers <> 1)
						  LEFT JOIN Un_Cotisation VCO ON VCO.OperID = VO.OperID
						  LEFT JOIN Un_ConventionOper VUCO ON VUCO.OperID = VO.OperID
						  LEFT JOIN Un_CESP VCE ON VCE.OperID = VO.OperID
						  LEFT JOIN dbo.Un_Unit VU ON VU.UnitID = VCO.UnitID
						  LEFT JOIN Un_OperLinkToCHQOperation VOL ON VOL.OperID = VO.OperID
					 WHERE VO.OperTypeID = 'OUT'
					   AND VO.OperDate >= '2008-08-29 00:00:00.000' and VO.OperDate <= O.dtSequence_Operation
					   AND VOC1.OperSourceID IS NULL
					   AND VOC2.OperID IS NULL
					   AND (ISNULL(VU.ConventionID,0) = T.iID_Convention
						   OR ISNULL(VUCO.ConventionID,0) = T.iID_Convention
						   OR ISNULL(VCE.ConventionID,0) = T.iID_Convention))
		  AND T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bRetrait_premature_avant_transfert = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_Oper O ON O.OperID = T.iID_Operation_Out
		WHERE 0 > (SELECT ISNULL(SUM(CO.Cotisation+CO.Fee),0)
				   FROM dbo.Un_Unit U
						JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
						JOIN Un_Oper O2 ON O2.OperID = CO.OperID
									   AND NOT EXISTS(SELECT *
													  FROM tblTEMP_InformationsIQEEPourOUT T2
													  WHERE T2.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
														AND T2.iID_Convention = T.iID_Convention
														AND (T2.iID_Operation_Out = CO.OperID OR T2.iID_Operation_TFR = CO.OperID)
														AND T2.iID_IQEE_OUT <> T.iID_IQEE_OUT)
									   AND (O2.dtSequence_Operation < O.dtSequence_Operation OR
											(O2.dtSequence_Operation = O.dtSequence_Operation AND O2.OperID < O.OperID))
				   WHERE U.ConventionID = T.iID_Convention)
		   OR EXISTS(SELECT *
					 FROM dbo.Un_Unit U
						  JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
						  JOIN Un_Oper O2 ON O2.OperID = CO.OperID
										 AND O2.OperTypeID IN ('RET','RES','TRA','RIO')
										 AND (O2.dtSequence_Operation < O.dtSequence_Operation OR
											 (O2.dtSequence_Operation = O.dtSequence_Operation AND O2.OperID < O.OperID))
					 WHERE U.ConventionID = T.iID_Convention)
		  AND T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bConvention_Destination_Fermee = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_ConventionConventionState CS ON CS.ConventionID = T.iID_Convention_Dest
												 AND CS.StartDate = (SELECT MAX(CS2.StartDate)
																	 FROM Un_ConventionConventionState CS2
																	 WHERE CS2.ConventionID = T.iID_Convention_Dest
																	   AND CS2.StartDate <= GETDATE())
												 AND CS.ConventionStateID <> 'REE'
		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert

		UPDATE T
		SET bAutre_raison_rejet_dans_meme_convention = 1
		FROM tblTEMP_InformationsIQEEPourOUT T
		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
		  AND T.bPas_TIO IS NULL
		  AND T.bConvention_OUT_pas_fermee IS NULL
		  AND T.bOUT_Deplace_deja_IQEE IS NULL
		  AND T.bAucun_Solde_IQEE_ou_Rendements IS NULL
		  AND T.bAutre_sortie_IQEE_apres_transfert IS NULL
		  AND T.bCompte_en_perte IS NULL
		  AND T.bChangement_Benef_non_reconnu_avant_transfert IS NULL
		  AND T.bTransfert_non_reconnu_avant_transfert IS NULL
		  AND T.bRetrait_premature_avant_transfert IS NULL
		  AND T.bConvention_Destination_Fermee IS NULL
		  AND EXISTS(SELECT *
					 FROM tblTEMP_InformationsIQEEPourOUT T2
					 WHERE T2.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
					   AND T2.iID_Convention = T.iID_Convention
					   AND (T2.bPas_TIO = 1
						  OR T2.bOUT_Deplace_deja_IQEE = 1
						  OR T2.bAutre_sortie_IQEE_apres_transfert = 1))

		------------------------------------------------------------------------
		-- Rouler les transferts possiblement admissibles à la mesure temporaire
		------------------------------------------------------------------------
		DECLARE curSelection CURSOR LOCAL FAST_FORWARD FOR
			SELECT T.iID_IQEE_OUT,T.iID_Convention,T.vcNo_Convention,T.iID_Convention_Dest,T.vcNo_Convention_Dest,
				   T.iID_TIO,T.iID_Operation_Out,T.iID_Operation_TFR,T.iID_Operation_TIN,T.iID_Cotisation_Out
			FROM tblTEMP_InformationsIQEEPourOUT T
			WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
			  AND T.bPas_TIO IS NULL
			  AND T.bConvention_OUT_pas_fermee IS NULL
			  AND T.bOUT_Deplace_deja_IQEE IS NULL
			  AND T.bAucun_Solde_IQEE_ou_Rendements IS NULL
			  AND T.bAutre_sortie_IQEE_apres_transfert IS NULL
			  AND T.bCompte_en_perte IS NULL
			  AND T.bChangement_Benef_non_reconnu_avant_transfert IS NULL
			  AND T.bTransfert_non_reconnu_avant_transfert IS NULL
			  AND T.bRetrait_premature_avant_transfert IS NULL
			  AND T.bConvention_Destination_Fermee IS NULL
			  AND T.bAutre_raison_rejet_dans_meme_convention IS NULL
			ORDER BY T.iID_Convention,T.iID_TIO

		SET @iID_Convention_Courant = 0

		OPEN curSelection
		FETCH NEXT FROM curSelection INTO @iID_IQEE_OUT,@iID_Convention,@vcNo_Convention,@iID_Convention_Dest,@vcNo_Convention_Dest,@iID_TIO,@iID_Operation_Out,
										  @iID_Operation_TFR,@iID_Operation_TIN,@iID_Cotisation_Out
		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @mSolde_CBQ_Avant = NULL
				SET @mSolde_MMQ_Avant = NULL
				SET @mSolde_MIM_Avant = NULL
				SET @mSolde_ICQ_Avant = NULL
				SET @mSolde_IMQ_Avant = NULL
				SET @mSolde_IIQ_Avant = NULL
				SET @mSolde_III_Avant = NULL
				SET @mSolde_IQI_Avant = NULL
				SET @mMontant_Total_Transfert = NULL
				SET @mMontant_JVM = NULL
				SET @fPourcentage_Transfert = NULL
				SET @mTransfert_CBQ = NULL
				SET @mTransfert_MMQ = NULL
				SET @mTransfert_MIM = NULL
				SET @mTransfert_ICQ = NULL
				SET @mTransfert_IMQ = NULL
				SET @mTransfert_IIQ = NULL
				SET @mTransfert_III = NULL
				SET @mTransfert_IQI = NULL
				SET @mSolde_CBQ_Apres = NULL
				SET @mSolde_MMQ_Apres = NULL
				SET @mSolde_MIM_Apres = NULL
				SET @mSolde_ICQ_Apres = NULL
				SET @mSolde_IMQ_Apres = NULL
				SET @mSolde_IIQ_Apres = NULL
				SET @mSolde_III_Apres = NULL
				SET @mSolde_IQI_Apres = NULL
				SET @bTransfert_a_0 = NULL
				SET @mMontant_Total_BEC_Rend_BEC = NULL
				SET @bPresence_Transfert_BEC = NULL
				SET @bAutres_raisons = NULL
				SET @mMontant_BEC = NULL
				SET @bPresence_Transfert_BEC_Avec_Rendement_BEC = NULL
				SET @bAdmissible_Transfert_IQEE = NULL

				-----------------------------------
				-- Calculer le montant du transfert
				-----------------------------------
				SELECT @mMontant_Total_Transfert = ISNULL(SUM(ConventionOperAmount),0)
				FROM Un_ConventionOper CO
				WHERE CO.OperID = @iID_Operation_Out
				  AND CO.ConventionID = @iID_Convention
				  AND CO.ConventionOperTypeID NOT IN ('FDI')

				SELECT @mMontant_Total_Transfert = @mMontant_Total_Transfert+ISNULL(SUM(fCESG),0)+ISNULL(SUM(fACESG),0)+ISNULL(SUM(fPG),0)
				FROM Un_CESP C
				WHERE C.OperID = @iID_Operation_Out
				  AND C.ConventionID = @iID_Convention

				SELECT @mMontant_BEC = ISNULL(SUM(fCLB),0)
				FROM Un_CESP C
				WHERE C.OperID = @iID_Operation_Out
				  AND C.ConventionID = @iID_Convention

				SELECT @mMontant_Total_Transfert = @mMontant_Total_Transfert+ISNULL(SUM(CO.Cotisation),0)+ISNULL(SUM(CO.Fee),0)
				FROM Un_Cotisation CO
					 JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
								   AND U.ConventionID = @iID_Convention
				WHERE CO.OperID = @iID_Operation_Out

				SET @mMontant_Total_Transfert = @mMontant_Total_Transfert*-1
				SET @mMontant_BEC = @mMontant_BEC*-1

				-- Rejeter les transferts à 0 ou les transferts de BEC
				IF @mMontant_Total_Transfert+@mMontant_BEC = 0
					SET @bTransfert_a_0 = 1
				ELSE
					BEGIN
						SELECT @mMontant_Total_BEC_Rend_BEC = ISNULL(SUM(ConventionOperAmount),0)
						FROM Un_ConventionOper CO
						WHERE CO.OperID = @iID_Operation_Out
						  AND CO.ConventionID = @iID_Convention
						  AND CO.ConventionOperTypeID IN ('IBC')

						SELECT @mMontant_Total_BEC_Rend_BEC = @mMontant_Total_BEC_Rend_BEC+ISNULL(SUM(fCLB),0)
						FROM Un_CESP C
						WHERE C.OperID = @iID_Operation_Out
						  AND C.ConventionID = @iID_Convention

						SET @mMontant_Total_BEC_Rend_BEC = @mMontant_Total_BEC_Rend_BEC*-1

						IF @mMontant_Total_BEC_Rend_BEC = @mMontant_BEC AND
						   @mMontant_Total_Transfert = 0
							SET @bPresence_Transfert_BEC = 1
						ELSE
							BEGIN
								IF @mMontant_Total_BEC_Rend_BEC = @mMontant_Total_Transfert+@mMontant_BEC
									SET @bPresence_Transfert_BEC_Avec_Rendement_BEC = 1
							END
					END

				IF @bTransfert_a_0 IS NULL AND @bPresence_Transfert_BEC IS NULL AND @bPresence_Transfert_BEC_Avec_Rendement_BEC IS NULL
					BEGIN
						---------------------------------------------------------------------------------
						-- Calculer la JVM au moment du transfert sans l'IQÉÉ et sans les montants du TFR
						---------------------------------------------------------------------------------

						-- Compter les soldes du BEC, subvention canadienne et programmes autres provinces
						SELECT @mMontant_JVM = ISNULL(SUM(C.fCESG+C.fACESG),0)+ISNULL(SUM(C.fPG),0) --Sans le BEC.  ISNULL(SUM(C.fCLB),0)+
						FROM Un_CESP C
							 JOIN Un_Oper O2 ON O2.OperID = @iID_Operation_Out
							 JOIN Un_Oper O ON O.OperID = C.OperID
										   AND (O.OperID = ISNULL(@iID_Operation_TFR,0) 
										        OR O.dtSequence_Operation < O2.dtSequence_Operation 
												OR (O.dtSequence_Operation = O2.dtSequence_Operation AND O.OperID < O2.OperID))
						WHERE C.ConventionID = @iID_Convention

						-- Compter le montant des revenus accumulés dans la convention
						SELECT @mMontant_JVM = @mMontant_JVM + ISNULL(SUM(CO.ConventionOperAmount),0)
						FROM Un_ConventionOper CO
							 JOIN Un_Oper O2 ON O2.OperID = @iID_Operation_Out
							 JOIN Un_Oper O ON O.OperID = CO.OperID
										   AND (O.OperID = ISNULL(@iID_Operation_TFR,0) 
										        OR O.dtSequence_Operation < O2.dtSequence_Operation 
												OR (O.dtSequence_Operation = O2.dtSequence_Operation AND O.OperID < O2.OperID))
						WHERE CO.ConventionID = @iID_Convention
						  AND CO.ConventionOperTypeID NOT IN ('CBQ','MMQ','MIM','ICQ','IMQ','IIQ','III','IQI','FDI')

						-- Compter le montant des cotisations et frais
						SELECT @mMontant_JVM = @mMontant_JVM + ISNULL(SUM(CO.Cotisation),0) + ISNULL(SUM(CO.Fee),0)
						FROM dbo.Un_Unit U
							 JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
							 JOIN Un_Oper O2 ON O2.OperID = @iID_Operation_Out
							 JOIN Un_Oper O ON O.OperID = CO.OperID
										   AND (O.OperID = ISNULL(@iID_Operation_TFR,0) 
										        OR O.dtSequence_Operation < O2.dtSequence_Operation 
												OR (O.dtSequence_Operation = O2.dtSequence_Operation AND O.OperID < O2.OperID))
						WHERE U.ConventionID = @iID_Convention

						---------------------------------------
						-- Calculer le pourcentage du transfert
						---------------------------------------
						IF @mMontant_JVM = 0
							SET @fPourcentage_Transfert = 0
						ELSE
							SET @fPourcentage_Transfert = @mMontant_Total_Transfert / @mMontant_JVM

						IF @fPourcentage_Transfert <= 0 OR
						   @fPourcentage_Transfert > 1 OR
						   @mMontant_Total_Transfert <= 0 OR
						   @mMontant_JVM <= 0 OR
						   @mMontant_JVM < @mMontant_Total_Transfert OR
						   @iID_Convention = @iID_Convention_Dest
							BEGIN
								SET @bAutres_raisons = 1
								SET @mTransfert_CBQ = NULL
								SET @mTransfert_MMQ = NULL
								SET @mTransfert_MIM = NULL
								SET @mTransfert_ICQ = NULL
								SET @mTransfert_IMQ = NULL
								SET @mTransfert_IIQ = NULL
								SET @mTransfert_III = NULL
								SET @mTransfert_IQI = NULL
								SET @mSolde_CBQ_Apres = NULL
								SET @mSolde_MMQ_Apres = NULL
								SET @mSolde_MIM_Apres = NULL
								SET @mSolde_ICQ_Apres = NULL
								SET @mSolde_IMQ_Apres = NULL
								SET @mSolde_IIQ_Apres = NULL
								SET @mSolde_III_Apres = NULL
								SET @mSolde_IQI_Apres = NULL
							END
						ELSE
							BEGIN
								SET @bAdmissible_Transfert_IQEE = 1

								-------------------------------------------------------------
								-- Calculer le solde des comptes de l’IQÉÉ avant le transfert
								-------------------------------------------------------------
								SELECT @mSolde_CBQ_Avant = ISNULL(SUM(CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END),0),
									   @mSolde_MMQ_Avant = ISNULL(SUM(CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END),0),
									   @mSolde_MIM_Avant = ISNULL(SUM(CASE WHEN CO.ConventionOperTypeID = 'MIM' THEN CO.ConventionOperAmount ELSE 0 END),0),
									   @mSolde_ICQ_Avant = ISNULL(SUM(CASE WHEN CO.ConventionOperTypeID = 'ICQ' THEN CO.ConventionOperAmount ELSE 0 END),0),
									   @mSolde_IMQ_Avant = ISNULL(SUM(CASE WHEN CO.ConventionOperTypeID = 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END),0),
									   @mSolde_IIQ_Avant = ISNULL(SUM(CASE WHEN CO.ConventionOperTypeID = 'IIQ' THEN CO.ConventionOperAmount ELSE 0 END),0),
									   @mSolde_III_Avant = ISNULL(SUM(CASE WHEN CO.ConventionOperTypeID = 'III' THEN CO.ConventionOperAmount ELSE 0 END),0),
									   @mSolde_IQI_Avant = ISNULL(SUM(CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END),0)
								FROM Un_ConventionOper CO
									 JOIN Un_Oper O2 ON O2.OperID = @iID_Operation_Out
									 JOIN Un_Oper O ON O.OperID = CO.OperID
												   AND O.OperID <> ISNULL(@iID_Operation_TFR,0)
												   AND (O.OperTypeID <> 'IQE' AND O.dtSequence_Operation < O2.dtSequence_Operation
														OR (O.OperTypeID <> 'IQE' AND O.dtSequence_Operation = O2.dtSequence_Operation AND O.OperID < O2.OperID)
														OR (O.OperTypeID = 'IQE' AND O.OperDate <= O2.dtSequence_Operation))
								WHERE CO.ConventionID = @iID_Convention
								  AND CO.ConventionOperTypeID IN ('CBQ','MMQ','MIM','ICQ','IMQ','IIQ','III','IQI')

								-----------------------------------------------------
								-- Calculer le montant d’IQÉÉ à transférer par compte
								-----------------------------------------------------
								SET @mTransfert_CBQ = ROUND(@mSolde_CBQ_Avant * @fPourcentage_Transfert,2)
								SET @mTransfert_MMQ = ROUND(@mSolde_MMQ_Avant * @fPourcentage_Transfert,2)
								SET @mTransfert_MIM = ROUND(@mSolde_MIM_Avant * @fPourcentage_Transfert,2)
								SET @mTransfert_ICQ = ROUND(@mSolde_ICQ_Avant * @fPourcentage_Transfert,2)
								SET @mTransfert_IMQ = ROUND(@mSolde_IMQ_Avant * @fPourcentage_Transfert,2)
								SET @mTransfert_IIQ = ROUND(@mSolde_IIQ_Avant * @fPourcentage_Transfert,2)
								SET @mTransfert_III = ROUND(@mSolde_III_Avant * @fPourcentage_Transfert,2)
								SET @mTransfert_IQI = ROUND(@mSolde_IQI_Avant * @fPourcentage_Transfert,2)

								-- Calculer le solde après le transfert
								SET @mSolde_CBQ_Apres = @mSolde_CBQ_Avant - @mTransfert_CBQ
								SET @mSolde_MMQ_Apres = @mSolde_MMQ_Avant - @mTransfert_MMQ
								SET @mSolde_MIM_Apres = @mSolde_MIM_Avant - @mTransfert_MIM
								SET @mSolde_ICQ_Apres = @mSolde_ICQ_Avant - @mTransfert_ICQ
								SET @mSolde_IMQ_Apres = @mSolde_IMQ_Avant - @mTransfert_IMQ
								SET @mSolde_IIQ_Apres = @mSolde_IIQ_Avant - @mTransfert_IIQ
								SET @mSolde_III_Apres = @mSolde_III_Avant - @mTransfert_III
								SET @mSolde_IQI_Apres = @mSolde_IQI_Avant - @mTransfert_IQI

								------------------------------------------------
								-- Insérer les transactions dans l'opération OUT
								------------------------------------------------
								IF @mTransfert_CBQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_Out
										   ,@iID_Convention
										   ,'CBQ'
										   ,@mTransfert_CBQ*-1)

								IF @mTransfert_MMQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_Out
										   ,@iID_Convention
										   ,'MMQ'
										   ,@mTransfert_MMQ*-1)

								IF @mTransfert_MIM > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_Out
										   ,@iID_Convention
										   ,'MIM'
										   ,@mTransfert_MIM*-1)

								IF @mTransfert_ICQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_Out
										   ,@iID_Convention
										   ,'ICQ'
										   ,@mTransfert_ICQ*-1)

								IF @mTransfert_IMQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_Out
										   ,@iID_Convention
										   ,'IMQ'
										   ,@mTransfert_IMQ*-1)

								IF @mTransfert_IIQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_Out
										   ,@iID_Convention
										   ,'IIQ'
										   ,@mTransfert_IIQ*-1)

								IF @mTransfert_III > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_Out
										   ,@iID_Convention
										   ,'III'
										   ,@mTransfert_III*-1)

								IF @mTransfert_IQI > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_Out
										   ,@iID_Convention
										   ,'IQI'
										   ,@mTransfert_IQI*-1)

								-- Insérer les transactions dans l'opération TIN
								IF @mTransfert_CBQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_TIN
										   ,@iID_Convention_Dest
										   ,'CBQ'
										   ,@mTransfert_CBQ)

								IF @mTransfert_MMQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_TIN
										   ,@iID_Convention_Dest
										   ,'MMQ'
										   ,@mTransfert_MMQ)

								IF @mTransfert_MIM > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_TIN
										   ,@iID_Convention_Dest
										   ,'MIM'
										   ,@mTransfert_MIM)

								IF @mTransfert_ICQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_TIN
										   ,@iID_Convention_Dest
										   ,'ICQ'
										   ,@mTransfert_ICQ)

								IF @mTransfert_IMQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_TIN
										   ,@iID_Convention_Dest
										   ,'IMQ'
										   ,@mTransfert_IMQ)

								IF @mTransfert_IIQ > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_TIN
										   ,@iID_Convention_Dest
										   ,'IIQ'
										   ,@mTransfert_IIQ)

								IF @mTransfert_III > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_TIN
										   ,@iID_Convention_Dest
										   ,'III'
										   ,@mTransfert_III)

								IF @mTransfert_IQI > 0
									INSERT INTO [dbo].[Un_ConventionOper]
											   ([OperID]
											   ,[ConventionID]
											   ,[ConventionOperTypeID]
											   ,[ConventionOperAmount])
									 VALUES
										   (@iID_Operation_TIN
										   ,@iID_Convention_Dest
										   ,'IQI'
										   ,@mTransfert_IQI)
							END
					END

				-- Sauvegarder les informations pour utilisation futur
				UPDATE tblTEMP_InformationsIQEEPourOUT
				SET	mSolde_CBQ_Avant = @mSolde_CBQ_Avant,
					mSolde_MMQ_Avant =	@mSolde_MMQ_Avant,
					mSolde_MIM_Avant =	@mSolde_MIM_Avant,
					mSolde_ICQ_Avant =	@mSolde_ICQ_Avant,
					mSolde_IMQ_Avant =	@mSolde_IMQ_Avant,
					mSolde_IIQ_Avant =	@mSolde_IIQ_Avant,
					mSolde_III_Avant =	@mSolde_III_Avant,
					mSolde_IQI_Avant =	@mSolde_IQI_Avant,
					mMontant_Total_Transfert = @mMontant_Total_Transfert,
					mMontant_JVM = @mMontant_JVM,
					fPourcentage_Transfert = @fPourcentage_Transfert,
					mTransfert_CBQ = @mTransfert_CBQ,
					mTransfert_MMQ = @mTransfert_MMQ,
					mTransfert_MIM = @mTransfert_MIM,
					mTransfert_ICQ = @mTransfert_ICQ,
					mTransfert_IMQ = @mTransfert_IMQ,
					mTransfert_IIQ = @mTransfert_IIQ,
					mTransfert_III = @mTransfert_III,
					mTransfert_IQI = @mTransfert_IQI,
					mSolde_CBQ_Apres = @mSolde_CBQ_Apres,
					mSolde_MMQ_Apres = @mSolde_MMQ_Apres,
					mSolde_MIM_Apres = @mSolde_MIM_Apres,
					mSolde_ICQ_Apres = @mSolde_ICQ_Apres,
					mSolde_IMQ_Apres = @mSolde_IMQ_Apres,
					mSolde_IIQ_Apres = @mSolde_IIQ_Apres,
					mSolde_III_Apres = @mSolde_III_Apres,
					mSolde_IQI_Apres = @mSolde_IQI_Apres,
					bTransfert_a_0 = @bTransfert_a_0,
					bAutres_raisons = @bAutres_raisons,
					bPresence_Transfert_BEC = @bPresence_Transfert_BEC,
					bPresence_Transfert_BEC_Avec_Rendement_BEC = @bPresence_Transfert_BEC_Avec_Rendement_BEC,
					bAdmissible_Transfert_IQEE = @bAdmissible_Transfert_IQEE
				WHERE iID_IQEE_OUT = @iID_IQEE_OUT

				FETCH NEXT FROM curSelection INTO @iID_IQEE_OUT,@iID_Convention,@vcNo_Convention,@iID_Convention_Dest,@vcNo_Convention_Dest,@iID_TIO,@iID_Operation_Out,
												  @iID_Operation_TFR,@iID_Operation_TIN,@iID_Cotisation_Out
			END
		CLOSE curSelection
		DEALLOCATE curSelection

		--------------------------------------------------------------------------------
		-- Annuler les transferts des conventions avec des rejets en cours de traitement
		--------------------------------------------------------------------------------
		DELETE CO
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_ConventionOper CO ON CO.OperID IN (T.iID_Operation_OUT,T.iID_Operation_TIN)
									  AND CO.ConventionOperTypeID IN ('CBQ','MMQ','MIM','ICQ','IMQ','IIQ','III','IQI')
		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
		  AND T.bAdmissible_Transfert_IQEE = 1
		  AND EXISTS(SELECT *
					 FROM tblTEMP_InformationsIQEEPourOUT T2
					 WHERE T2.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
					   AND T2.iID_Convention = T.iID_Convention
					   AND T2.iID_TIO < T.iID_TIO
					   AND (T2.bTransfert_a_0 = 1 OR T2.bAutres_raisons = 1 OR T2.bPresence_Transfert_BEC_Avec_Rendement_BEC = 1))

		UPDATE tblTEMP_InformationsIQEEPourOUT
		SET	mSolde_CBQ_Avant = NULL,
			mSolde_MMQ_Avant =	NULL,
			mSolde_MIM_Avant =	NULL,
			mSolde_ICQ_Avant =	NULL,
			mSolde_IMQ_Avant =	NULL,
			mSolde_IIQ_Avant =	NULL,
			mSolde_III_Avant =	NULL,
			mSolde_IQI_Avant =	NULL,
			mTransfert_CBQ = NULL,
			mTransfert_MMQ = NULL,
			mTransfert_MIM = NULL,
			mTransfert_ICQ = NULL,
			mTransfert_IMQ = NULL,
			mTransfert_IIQ = NULL,
			mTransfert_III = NULL,
			mTransfert_IQI = NULL,
			mSolde_CBQ_Apres = NULL,
			mSolde_MMQ_Apres = NULL,
			mSolde_MIM_Apres = NULL,
			mSolde_ICQ_Apres = NULL,
			mSolde_IMQ_Apres = NULL,
			mSolde_IIQ_Apres = NULL,
			mSolde_III_Apres = NULL,
			mSolde_IQI_Apres = NULL,
			bAutre_raison_rejet_dans_meme_convention = 1,
			bAdmissible_Transfert_IQEE = NULL
		FROM tblTEMP_InformationsIQEEPourOUT T
		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
		  AND T.bAdmissible_Transfert_IQEE = 1
		  AND EXISTS(SELECT *
					 FROM tblTEMP_InformationsIQEEPourOUT T2
					 WHERE T2.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
					   AND T2.iID_Convention = T.iID_Convention
					   AND T2.iID_TIO < T.iID_TIO
					   AND (T2.bTransfert_a_0 = 1 OR T2.bAutres_raisons = 1 OR T2.bPresence_Transfert_BEC_Avec_Rendement_BEC = 1))

		------------------------------------------------------------------------
		-- Annuler les transferts des conventions qui ne font pas de TIO complet
		------------------------------------------------------------------------
		DELETE CO
		FROM tblTEMP_InformationsIQEEPourOUT T
			 JOIN Un_ConventionOper CO ON CO.OperID IN (T.iID_Operation_OUT,T.iID_Operation_TIN)
									  AND CO.ConventionOperTypeID IN ('CBQ','MMQ','MIM','ICQ','IMQ','IIQ','III','IQI')
		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
		  AND T.bAdmissible_Transfert_IQEE = 1
		  AND T.fPourcentage_Transfert <> 1
		  AND NOT EXISTS(SELECT *
					     FROM tblTEMP_InformationsIQEEPourOUT T2
						 WHERE T2.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
					       AND T2.iID_Convention = T.iID_Convention
						   AND T2.iID_TIO > T.iID_TIO
						   AND T2.fPourcentage_Transfert = 1)

		UPDATE tblTEMP_InformationsIQEEPourOUT
		SET	mSolde_CBQ_Avant = NULL,
			mSolde_MMQ_Avant =	NULL,
			mSolde_MIM_Avant =	NULL,
			mSolde_ICQ_Avant =	NULL,
			mSolde_IMQ_Avant =	NULL,
			mSolde_IIQ_Avant =	NULL,
			mSolde_III_Avant =	NULL,
			mSolde_IQI_Avant =	NULL,
			mTransfert_CBQ = NULL,
			mTransfert_MMQ = NULL,
			mTransfert_MIM = NULL,
			mTransfert_ICQ = NULL,
			mTransfert_IMQ = NULL,
			mTransfert_IIQ = NULL,
			mTransfert_III = NULL,
			mTransfert_IQI = NULL,
			mSolde_CBQ_Apres = NULL,
			mSolde_MMQ_Apres = NULL,
			mSolde_MIM_Apres = NULL,
			mSolde_ICQ_Apres = NULL,
			mSolde_IMQ_Apres = NULL,
			mSolde_IIQ_Apres = NULL,
			mSolde_III_Apres = NULL,
			mSolde_IQI_Apres = NULL,
			bAutres_raisons = 1,
			bAdmissible_Transfert_IQEE = NULL
		FROM tblTEMP_InformationsIQEEPourOUT T
		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
		  AND T.bAdmissible_Transfert_IQEE = 1
		  AND T.fPourcentage_Transfert <> 1
		  AND NOT EXISTS(SELECT *
					     FROM tblTEMP_InformationsIQEEPourOUT T2
						 WHERE T2.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
					       AND T2.iID_Convention = T.iID_Convention
						   AND T2.iID_TIO > T.iID_TIO
						   AND T2.fPourcentage_Transfert = 1)

		---------------------------------------------------------------------------
		-- Transférer le solde d'IQÉÉ restant pour l'IQÉÉ reçu après les transferts
		---------------------------------------------------------------------------
		-- Note: cette partie du code présume que tous les cas de transfert 
-- TODO: A faire.  Le montant transférer doit être le montant des opérations IQE reçus après toutes les opérations OUT de la convention.
--       Voir s'il y a d'autres montants transféré avec l'IQÉÉ

-- Sauvegarde de code pour la réalisation
-----------------------------------------
--		DECLARE @bConvention_avec_rejet_de_transfert BIT,
--				@bPas_Solde_IQEE_pour_Retransfert BIT,
--				@bSolde_IQEE_Different_entree_IQE BIT,
--				@bAutres_montant_que_IQEE BIT
--
--		UPDATE tblTEMP_InformationsIQEEPourOUT
--		SET bConvention_avec_rejet_de_transfert = 1
--		FROM tblTEMP_InformationsIQEEPourOUT T
--		WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
--		  AND T.bAdmissible_Transfert_IQEE = 1
--		  AND EXISTS(SELECT *
--					 FROM tblTEMP_InformationsIQEEPourOUT T2
--					 WHERE T2.
--
--		-------------------------------------------------------------
--		-- Rouler les retransferts admissibles à la mesure temporaire
--		-------------------------------------------------------------
--
--
--
--		DECLARE curSelection CURSOR LOCAL FAST_FORWARD FOR
--			SELECT T.iID_IQEE_OUT,T.iID_Convention,T.vcNo_Convention,T.iID_Convention_Dest,T.vcNo_Convention_Dest,
--				   T.iID_TIO,T.iID_Operation_Out,T.iID_Operation_TFR,T.iID_Operation_TIN,T.iID_Cotisation_Out
--			FROM tblTEMP_InformationsIQEEPourOUT T
--			WHERE T.dtDate_Essais_Transfert = @dtDate_Essais_Transfert
--			  AND T.bPas_TIO IS NULL
--			  AND T.bConvention_OUT_pas_fermee IS NULL
--			  AND T.bOUT_Deplace_deja_IQEE IS NULL
--			  AND T.bAucun_Solde_IQEE_ou_Rendements IS NULL
--			  AND T.bAutre_sortie_IQEE_apres_transfert IS NULL
--			  AND T.bCompte_en_perte IS NULL
--			  AND T.bChangement_Benef_non_reconnu_avant_transfert IS NULL
--			  AND T.bTransfert_non_reconnu_avant_transfert IS NULL
--			  AND T.bRetrait_premature_avant_transfert IS NULL
--			  AND T.bConvention_Destination_Fermee IS NULL
--			  AND T.bAutre_raison_rejet_dans_meme_convention IS NULL
--			ORDER BY T.iID_Convention,T.iID_TIO
--
--		SET @iID_Convention_Courant = 0
--
--		OPEN curSelection
--		FETCH NEXT FROM curSelection INTO @iID_IQEE_OUT,@iID_Convention,@vcNo_Convention,@iID_Convention_Dest,@vcNo_Convention_Dest,@iID_TIO,@iID_Operation_Out,
--										  @iID_Operation_TFR,@iID_Operation_TIN,@iID_Cotisation_Out
--		WHILE @@FETCH_STATUS = 0
--			BEGIN
--
--
--
--				-- Sauvegarder les informations pour utilisation futur
--				UPDATE tblTEMP_InformationsIQEEPourOUT
--				SET	mSolde_CBQ_Avant = @mSolde_CBQ_Avant,
--					mSolde_MMQ_Avant =	@mSolde_MMQ_Avant,
--					mSolde_MIM_Avant =	@mSolde_MIM_Avant,
--					mSolde_ICQ_Avant =	@mSolde_ICQ_Avant,
--					mSolde_IMQ_Avant =	@mSolde_IMQ_Avant,
--					mSolde_IIQ_Avant =	@mSolde_IIQ_Avant,
--					mSolde_III_Avant =	@mSolde_III_Avant,
--					mSolde_IQI_Avant =	@mSolde_IQI_Avant,
--					mMontant_Total_Transfert = @mMontant_Total_Transfert,
--					mMontant_JVM = @mMontant_JVM,
--					fPourcentage_Transfert = @fPourcentage_Transfert,
--					mTransfert_CBQ = @mTransfert_CBQ,
--					mTransfert_MMQ = @mTransfert_MMQ,
--					mTransfert_MIM = @mTransfert_MIM,
--					mTransfert_ICQ = @mTransfert_ICQ,
--					mTransfert_IMQ = @mTransfert_IMQ,
--					mTransfert_IIQ = @mTransfert_IIQ,
--					mTransfert_III = @mTransfert_III,
--					mTransfert_IQI = @mTransfert_IQI,
--					mSolde_CBQ_Apres = @mSolde_CBQ_Apres,
--					mSolde_MMQ_Apres = @mSolde_MMQ_Apres,
--					mSolde_MIM_Apres = @mSolde_MIM_Apres,
--					mSolde_ICQ_Apres = @mSolde_ICQ_Apres,
--					mSolde_IMQ_Apres = @mSolde_IMQ_Apres,
--					mSolde_IIQ_Apres = @mSolde_IIQ_Apres,
--					mSolde_III_Apres = @mSolde_III_Apres,
--					mSolde_IQI_Apres = @mSolde_IQI_Apres,
--					bTransfert_a_0 = @bTransfert_a_0,
--					bAutres_raisons = @bAutres_raisons,
--					bPresence_Transfert_BEC = @bPresence_Transfert_BEC
--				WHERE iID_IQEE_OUT = @iID_IQEE_OUT
--
--				FETCH NEXT FROM curSelection INTO @iID_IQEE_OUT,@iID_Convention,@vcNo_Convention,@iID_Convention_Dest,@vcNo_Convention_Dest,@iID_TIO,@iID_Operation_Out,
--												  @iID_Operation_TFR,@iID_Operation_TIN,@iID_Cotisation_Out
--			END
--		CLOSE curSelection
--		DEALLOCATE curSelection
--
--
--		-- Construire une liste de cas théoriquement admissible
--		-------------------------------------------------------
--		INSERT INTO tblTEMP_InformationsIQEEPourOUT
--			(dtDate_Essais_Transfert,bRetransfert_Solde_IQEE,iID_Convention,vcNo_Convention,iID_TIO,iID_Operation_Out,iID_Operation_TFR,iID_Operation_TIN,iID_Cotisation_Out,iID_Convention_Dest,vcNo_Convention_Dest)
--		SELECT DISTINCT @dtDate_Essais_Transfert,C.ConventionID,C.ConventionNo,TIO.iTIOID,TIO.iOUTOperID,TIO.iTFROperID,TIO.iTINOperID,COC.CotisationID,C2.ConventionID,C2.ConventionNo
--		FROM Un_Oper O
--			 LEFT JOIN Un_TIO TIO ON TIO.iOUTOperID = O.OperID
--			 LEFT JOIN Un_OperCancelation OC1 ON OC1.OperID = O.OperID
--			 LEFT JOIN Un_OperCancelation OC2 ON OC2.OperSourceID = O.OperID
--			 LEFT JOIN Un_ConventionOper COA ON COA.OperID = O.OperID
--			 LEFT JOIN Un_CESP COB ON COB.OperID = O.OperID
--			 LEFT JOIN Un_Cotisation COC ON COC.OperID = O.OperID
--			 LEFT JOIN dbo.Un_Unit U ON U.UnitID = COC.UnitID
--			 LEFT JOIN dbo.Un_Convention C ON C.ConventionID = COALESCE(U.ConventionID,COA.ConventionID,COB.ConventionID)
--			 LEFT JOIN Un_Oper O2 ON O2.OperID = iTINOperID
--			 LEFT JOIN Un_ConventionOper COA2 ON COA2.OperID = O2.OperID
--			 LEFT JOIN Un_CESP COB2 ON COB2.OperID = O2.OperID
--			 LEFT JOIN Un_Cotisation COC2 ON COC2.OperID = O2.OperID
--			 LEFT JOIN dbo.Un_Unit U2 ON U2.UnitID = COC2.UnitID
--			 LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = COALESCE(U2.ConventionID,COA2.ConventionID,COB2.ConventionID)
--		WHERE O.dtSequence_Operation >= '2008-08-29 00:00:00.000'
--		  -- Transfert OUT
--		  AND O.OperTypeID = 'OUT'
--		  -- Pas une annulation
--		  AND OC1.OperID IS NULL
--		  -- Pas annulée
--		  AND OC2.OperSourceID IS NULL
--		ORDER BY C.ConventionNo
--

--							--- RÉCUPÉRATION DU CONNECTID SYSTÈME À PARTIR DE LA TABLE UN_DEF
--							SELECT @iConnectId = MAX(CO.ConnectID)
--							FROM Mo_Connect CO
--							WHERE CO.UserID = 519626
--
--							/* Obtenir la transaction OUT originale */
--							SELECT 
--								@ExternalPlanID = ExternalPlanID
--								,@tiBnfRelationWithOtherConvBnf = tiBnfRelationWithOtherConvBnf
--								,@vcOtherConventionNo = vcOtherConventionNo
--								,@tiREEEType = tiREEEType
--								,@bEligibleForCESG = bEligibleForCESG
--								,@bEligibleForCLB = bEligibleForCLB
--								,@bOtherContratBnfAreBrothers = bOtherContratBnfAreBrothers
--								,@fYearBnfCot = fYearBnfCot
--								,@fNoCESGCotBefore98 = fNoCESGCotBefore98
--								,@fNoCESGCot98AndAfter = fNoCESGCot98AndAfter
--								,@fCESGCot = fCESGCot
--								,@fCESG = fCESG
--								,@fCLB = fCLB
--								,@fAIP = fAIP
--								,@fMarketValue = fMarketValue
--							FROM dbo.Un_OUT
--							WHERE OperId = @iID_OPER
--
--							/* Création d'une nouvelle opération OUT */
--							EXECUTE @iID_OPER = dbo.SP_IU_UN_OPER @iConnectId, 0, 'OUT', @dtDateTransfert
--
--							/* Insérer une nouvelle transaction OUT basé sur la transaction originale */
--							INSERT INTO dbo.Un_OUT
--							VALUES (@iID_OPER
--									,@ExternalPlanID
--									,@tiBnfRelationWithOtherConvBnf
--									,@vcOtherConventionNo
--									,@tiREEEType
--									,@bEligibleForCESG
--									,@bEligibleForCLB
--									,@bOtherContratBnfAreBrothers
--									,0
--									,0
--									,0
--									,0
--									,0
--									,0
--									,0
--									,0
--									,0)

		-- Remettre la date de barrure des opérations comme elle était avant le début du traitement
		UPDATE Un_Def
		SET LastVerifDate = @dtDate_Barrure_Operation

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- Lever l'erreur et faire le rollback
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT

		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()

		IF (XACT_STATE()) = -1 AND @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;
		RETURN -1
	END CATCH

	-- Retourner l'identifiant des informations
	RETURN 0
END


