/***********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_ObtenirMontantIQEEPourPAE
Nom du service		: Obtenir les montants d'IQÉÉ pour la production d'un PAE.
But 				: Mesure temporaire qui a pour objectif de sortir les montants d'IQÉÉ avec les PAE avant que les
					  montants d'IQÉÉ soient injectés dans les conventions.  Elle donne les montants d'IQÉÉ à sortir
					  et enregistre les chiffres dans une table temporaire afin de faciliter la finalisation des
					  données lors de l'injection des données dans les conventions.
Facette				: IQÉÉ

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-07-13		Éric Deshaies						Création du service
		2009-12-03		Éric Deshaies						L'IQÉÉ est maintenant dans les conventions
															- Calculer les montants à partir des conventions
															  au lieu des réponses de l'IQÉÉ
															- Créer les transactions IQÉÉ et d'intérêts d'IQÉÉ
															  dans les conventions
															- Mettre les intérêts générés par GUI dans le chèque
		2010-08-17		Éric Deshaies						Laisser passer l'IQÉÉ pour les conventions
															fermée et avec retrait prématuré dans les
															conventions "T" à cause du paiement des frais
															dans le TFR.
		2011-04-15		Éric Deshaies						Ne pas sortir l’IQÉÉ reçu entre la 
															date d’importation et la date de dépôt.
		2012-05-17		Éric Michaud						Changement de la variable @dtDate_Debut_Cotisation
        2016-03-01      Steeve Picard						Déduire le montant de RIN avec preuve du total de cotisation subventionnable à partir de 2016
		2016-05-04		Steeve Picard						Renommage de la fonction «fnIQEE_ObtenirDateEnregistrementRQ» qui était auparavant «fnIQEE_ObtenirDateEnregistrementRQ»
        2016-06-09      Steeve Picard                       Modification au niveau des paramètres de la fonction «dbo.fntIQEE_CalculerMontantsDemande»
        2017-12-12      Pierre-Luc Simard                   Ajout du compte RST dans le compte BRS
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_ObtenirMontantIQEEPourPAE]
(
	@iID_Convention INT,
	@iID_Operation INT
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iID_Operation_Cheque INT,
			@bPAE_Destine_Beneficiaire BIT,
	
			@vcNo_Convention VARCHAR(15),
			@bConvention_Rejetee BIT,

			@bBeneficiare_Quebec BIT,
			@vcVille_Beneficiaire VARCHAR(30),
			@vcProvince_Beneficiaire VARCHAR(75),
			@vcPays_Beneficiaire VARCHAR(3),
			@vcCodePostal_Beneficiaire VARCHAR(10),
			@vcCode_Province_Beneficiaire VARCHAR(75),

			@bConvention_Fermee BIT,
			@bRempl_Benef_Non_Reconnu BIT,
			@bTransfert_Non_Autorise BIT,
			@mTotal_Cotisations_Subventionnables MONEY,
			@mTotal_RIN_AvecPreuve MONEY,
			@bRetrait_Premature BIT,

			@mMontant_PAE MONEY,
			@mBEC MONEY,
			@mSubvention_Canadienne MONEY,
			@mProgrammes_Autres_Provinces MONEY,
			@mJuste_Valeur_Marchande MONEY,
			@mJVM MONEY,
			@fPourcentage_PAE FLOAT,

			@mReponse_Credit_Base MONEY,
			@mReponse_Majoration MONEY,
			@mReponse_Interets_RQ MONEY,
			@mCredit_Base_Deja_Verse MONEY,
			@mMajoration_Deja_Verse MONEY,
			@mInterets_RQ_Deja_Verse MONEY,
			@mCredit_Base_Verse MONEY,
			@mMajoration_Verse MONEY,
			@mInterets_RQ_Verse MONEY,

			@iID_IQEE_PAE INT,

			@mSolde_Credit_Base MONEY,
			@mSolde_Majoration MONEY,
			@mSolde_Interets_RQ MONEY,
			@mSolde_Interets_IQI MONEY,
			@mSolde_Interets_ICQ MONEY,
			@mSolde_Interets_IMQ MONEY,
			@mSolde_Interets_IIQ MONEY,
			@mSolde_Interets_III MONEY,
			@mInterets_IQI_Verse MONEY,
			@mInterets_ICQ_Verse MONEY,
			@mInterets_IMQ_Verse MONEY,
			@mInterets_IIQ_Verse MONEY,
			@mInterets_III_Verse MONEY

	-- Déterminer l'identifiant de l'opération de chèque
	SELECT @iID_Operation_Cheque = OL.iOperationID
	FROM Un_OperLinkToCHQOperation OL 
		JOIN CHQ_Operation CO1 ON CO1.iOperationID = OL.iOperationID
	WHERE OL.OperID = @iID_Operation	

	----------------------------------------------------------
	-- Déterminer si le PAE est destiné au bénéficiaire ou non
	----------------------------------------------------------
	IF EXISTS (SELECT *
			   FROM Un_OperLinkToCHQOperation OL 
					JOIN CHQ_Operation CO1 ON CO1.iOperationID = OL.iOperationID
					JOIN CHQ_OperationPayee OP ON OP.iOperationID = CO1.iOperationID
					JOIN dbo.Un_Convention C ON C.ConventionID = @iID_Convention
			   WHERE OL.OperID = @iID_Operation
				 AND OP.iPayeeID = C.BeneficiaryID)
		SET @bPAE_Destine_Beneficiaire = 1
	ELSE
		SET @bPAE_Destine_Beneficiaire = 0

	--------------------------------------------------------------
	-- Déterminer si le bénéficiaire est résident du Québec ou non
	--------------------------------------------------------------

	-- Trouver l'adresse courante du bénéficiaire
	SELECT @vcVille_Beneficiaire = AB.City,
		   @vcProvince_Beneficiaire = AB.StateName,
		   @vcPays_Beneficiaire = AB.CountryID,
		   @vcCodePostal_Beneficiaire = UPPER(REPLACE(AB.ZipCode,' ','')),
		   @vcNo_Convention = C.ConventionNo
	FROM dbo.Un_Convention C
		 JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
		 JOIN dbo.Mo_Adr AB ON AB.AdrID = HB.AdrID
	WHERE C.ConventionID = @iID_Convention

	-- Déterminer la province et le pays du bénéficiaire
	SELECT @vcCode_Province_Beneficiaire = vcCode_Province
	FROM [dbo].[fntGENE_ObtenirProvincePays](@vcProvince_Beneficiaire, @vcVille_Beneficiaire, @vcPays_Beneficiaire,
											 @vcCodePostal_Beneficiaire)

	IF @vcCode_Province_Beneficiaire = 'QC'
		SET @bBeneficiare_Quebec = 1
	ELSE
		SET @bBeneficiare_Quebec = 0

	-----------------------------------------------------------------------------------------------------------------
	-- Déterminer si la convention doit être rejetée parce qu'elle a fait l'objet de transactions manuelles de l'IQÉÉ
	-- avant que les transactions soient implantées dans UniAccès.
	-- Liste mise à jour avec la liste du suivi manuel pour les transferts OUT et les PAE/bourses au 31 août 2009
	-----------------------------------------------------------------------------------------------------------------
-- Plus nécessaire étant donné que l'IQÉÉ est dans les conventions
--	IF @vcNo_Convention IN ('U-20060926024','R-20060718032','R-20060523041','U-20060620033','U-20060926025',
--							'R-20070725009','R-20070725010','R-20060831054','R-20060831055','U-20071015020',
--							'U-20071015021','R-20031114009','U-20031114025','R-20050714005','U-20071107005',
--							'U-20030220006','2123897','U-20050627001','U-20040621037','U-20070806034','R-20070321054',
--							'R-20060921031','R-20060921030','U-20040419003','U-20020109022','U-20071121050',
--							'U-20070920182','U-20070921013','U-20070604011','R-20080108025','R-20081211081',
--							'R-20080115004','R-20060919056','U-20080318041','R-20040316010','R-20040316011',
--							'U-20040316027','U-20060420053','U-20081107025','U-20081212010','U-20071126028',
--							'U-20060309002','R-20070529017 ','R-20070529018','I-20071220003','I-20031223002',
--							'I-20060208001','I-20061208001','2023790','930029','1193500','1133829','I-20061222002',
--							'1534083','1256661','1413361','1403727','1492480','1493421','2008650','1341356',
--							'1482598','1197873','2118509','1104101','1267221','1509242','C-20000329039','2010433',
--							'1337362','1597379','C-20010104051','I-20081223001','I-20041109001','2010425',
--							'1106999','T-20080501031','T-20080501021','T-20080501102','T-20080501017',
--							'T-20081101154','T-20080501082','T-20090501005','T-20090501007','T-20090501141',
--							'T-20090501042','T-20090501109','T-20090501120','T-20090501140','T-20090501124',
--							'T-20080501064','T-20080501091','T-20080501091','T-20080501091','T-20080501091',
--							'T-20080501110','T-20090515001','T-20080501023','T-20080501023','T-20080501046',
--							'T-20080501024','I-20081112002','I-20080812001','I-20081124001','I-20081006001',
--							'I-20081204003','I-20081015001','I-20080627001','I-20080506001','I-20081126001',
--							'I-20081211001','I-20071220002','I-20081204001','I-20081125002','I-20081120002',
--							'I-20081022003','I-20081218003','I-20081203001','I-20081120003','I-20081125003',
--							'I-20081120008','I-20081112001','I-20081022002','I-20040521001','I-20081120009',
--							'I-20040929001','I-20081118002','I-20081105002','I-20080819001','1260259','1128670',
--							'2009401','1389843','I-20060619001','I-20081106001','I-20081118001','I-20080708001',
--							'1182099','1181976','U-20041025003','1509473','1509481','1575094','2124887',
--							'I-20081215001','1194730','I-20081120010','I-20081120012','T-20080501027',
--							'T-20090501076','T-20080501045','T-20090603001','T-20080501032','T-20081101139',
--							'T-20081101139','T-20090501031','T-20090501031','T-20080501076','T-20080501049',
--							'T-20080501071','I-20070925001','I-20081112003','F-20011119002','I-20050506001',
--							'I-20070925002','I-20070705002','I-20031223005','2039499','D-20010730001',
--							'1449340','2083034','I-20071107001','C-19991018042','I-20050923003','I-20050923002',
--							'T-20081101006','T-20081101017','T-20081101023','T-20081101028','T-20081101067')
--		SET @bConvention_Rejetee = 1
--	ELSE
		SET @bConvention_Rejetee = 0

	-------------------------------------------------------------
	-- Simuler s'il y aurait un remboursement de l'IQÉÉ à prévoir
	-------------------------------------------------------------

	-- Définir la période de simulation des événements spéciaux
	DECLARE @dtDate_Debut_Cotisation DATETIME,
			@dtDate_Fin_Cotisation DATETIME

	SET @dtDate_Debut_Cotisation = '2007-02-19'
	SET @dtDate_Fin_Cotisation = DATEADD(minute,-10,GETDATE())

	-- Déterminer si l'IQÉÉ doit être remboursé parce que la convention est fermée
	IF EXISTS (SELECT *
				FROM dbo.Un_Convention C
					JOIN Un_ConventionConventionState CS ON CS.ConventionID = C.ConventionID 
														AND CS.StartDate >= @dtDate_Debut_Cotisation
														AND	CS.ConventionStateID = 'FRM'
														AND CS.StartDate = (SELECT MAX(CS2.StartDate)
																			FROM Un_ConventionConventionState CS2
																			WHERE CS2.ConventionID = C.ConventionID
																			  AND CS2.StartDate <= @dtDate_Fin_Cotisation)
				WHERE C.ConventionID = @iID_Convention)
       AND SUBSTRING(@vcNo_Convention,1,1) <> 'T'
		SET @bConvention_Fermee = 1
	ELSE
		SET @bConvention_Fermee = 0
	
	-- Déterminer si l'IQÉÉ doit être remboursé parce qu'il y a eu un remplacement de bénéficiaire non reconnu dans la convention
	IF EXISTS (SELECT *
				FROM [dbo].[fntCONV_RechercherChangementsBeneficiaire](NULL, NULL, @iID_Convention, NULL,
													@dtDate_Debut_Cotisation, @dtDate_Fin_Cotisation,
												   NULL, NULL, NULL, NULL, NULL, NULL, NULL) C
				JOIN dbo.Mo_Human HN ON HN.HumanID = C.iID_Nouveau_Beneficiaire
				JOIN dbo.Mo_Human HA ON HA.HumanID = C.iID_Ancien_Beneficiaire
				WHERE C.vcCode_Raison <> 'INI'
				AND NOT ([dbo].[fn_Mo_Age](HN.BirthDate,case when C.dtDate_Changement_Beneficiaire < '2011-01-01' then C.dtDate_Changement_Beneficiaire else [dbo].[fnIQEE_ObtenirDateEnregistrementRQ](@iID_Convention) end) < 21
						 AND C.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 1)
				AND NOT ([dbo].[fn_Mo_Age](HA.BirthDate,case when C.dtDate_Changement_Beneficiaire < '2011-01-01' then C.dtDate_Changement_Beneficiaire else [dbo].[fnIQEE_ObtenirDateEnregistrementRQ](@iID_Convention) end) < 21
						 AND [dbo].[fn_Mo_Age](HN.BirthDate,case when C.dtDate_Changement_Beneficiaire < '2011-01-01' then C.dtDate_Changement_Beneficiaire else [dbo].[fnIQEE_ObtenirDateEnregistrementRQ](@iID_Convention) end) < 21
						 AND C.bLien_Sang_Avec_Souscripteur_Initial = 1))
		SET @bRempl_Benef_Non_Reconnu = 1
	ELSE
		SET @bRempl_Benef_Non_Reconnu = 0

	-- Déterminer si l'IQÉÉ doit être remboursé parce qu'il y a eu un transfert non autorisé dans la convention
	IF EXISTS (SELECT *
				FROM Un_Oper O
					 LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
					 LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
					 JOIN Un_OUT TOU ON TOU.OperID = O.OperID
									AND (TOU.tiBnfRelationWithOtherConvBnf = 3 OR TOU.bOtherContratBnfAreBrothers <> 1)
 					 LEFT JOIN Un_Cotisation CO ON CO.OperID = O.OperID
 					 LEFT JOIN Un_ConventionOper UCO ON UCO.OperID = O.OperID
 					 LEFT JOIN Un_CESP CE ON CE.OperID = O.OperID
					 LEFT JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
					 LEFT JOIN Un_OperLinkToCHQOperation OL ON OL.OperID = O.OperID
				WHERE O.OperTypeID = 'OUT'
				  AND O.OperDate >= @dtDate_Debut_Cotisation and O.OperDate <= @dtDate_Fin_Cotisation
				  AND OC1.OperSourceID IS NULL
				  AND OC2.OperID IS NULL
				  AND (ISNULL(U.ConventionID,0) = @iID_Convention
					  OR ISNULL(UCO.ConventionID,0) = @iID_Convention
					  OR ISNULL(CE.ConventionID,0) = @iID_Convention))
		SET @bTransfert_Non_Autorise = 1
	ELSE
		SET @bTransfert_Non_Autorise = 0

	-- Déterminer si l'IQÉÉ doit être remboursé en parti parce qu'il y a eu un retrait prématuré des cotisations

	-- Calculer les montants d'une éventuelle demande d'IQÉÉ dans l'année fiscale 2008
	SELECT @mTotal_Cotisations_Subventionnables = mTotal_Cotisations_Subventionnables,
	       @mTotal_RIN_AvecPreuve = mTotal_RIN_AvecPreuve
	FROM [dbo].[fntIQEE_CalculerMontantsDemande](@iID_Convention, @dtDate_Debut_Cotisation, @dtDate_Fin_Cotisation, DEFAULT)

    -- Déduire le montant de RIN avec preuve du total de cotisation subventionnable à partir de l'année 2016
    IF Year(@dtDate_Fin_Cotisation) > 2015
        SET @mTotal_Cotisations_Subventionnables = @mTotal_Cotisations_Subventionnables + @mTotal_RIN_AvecPreuve

	-- Traiter uniquement les conventions ayant un retrait prématuré de cotisations
	IF @mTotal_Cotisations_Subventionnables < 0
       AND SUBSTRING(@vcNo_Convention,1,1) <> 'T'
		SET @bRetrait_Premature = 1
	ELSE
		SET @bRetrait_Premature = 0

	-------------------------------
	-- Calculer les montants d'IQÉÉ
	-------------------------------
	SET	@mMontant_PAE = NULL
	SET	@mJVM = NULL
	SET	@fPourcentage_PAE = NULL
	SET	@mReponse_Credit_Base = NULL
	SET	@mReponse_Majoration = NULL
	SET	@mReponse_Interets_RQ = NULL
	SET	@mCredit_Base_Deja_Verse = NULL
	SET	@mMajoration_Deja_Verse = NULL
	SET	@mInterets_RQ_Deja_Verse = NULL
	SET	@mCredit_Base_Verse = NULL
	SET	@mMajoration_Verse = NULL
	SET	@mInterets_RQ_Verse = NULL
	SET @mSolde_Credit_Base = NULL
	SET @mSolde_Majoration = NULL
	SET @mSolde_Interets_RQ = NULL
	SET @mSolde_Interets_IQI = NULL
	SET @mSolde_Interets_ICQ = NULL
	SET @mSolde_Interets_IMQ = NULL
	SET @mSolde_Interets_IIQ = NULL
	SET @mSolde_Interets_III = NULL
	SET @mInterets_IQI_Verse = NULL
	SET @mInterets_ICQ_Verse = NULL
	SET @mInterets_IMQ_Verse = NULL
	SET @mInterets_IIQ_Verse = NULL
	SET @mInterets_III_Verse = NULL

	-- Si le bénéficiaire a le droit à l'IQÉÉ
	IF @bPAE_Destine_Beneficiaire = 1 AND
	   @bBeneficiare_Quebec = 1 AND
	   @bConvention_Rejetee = 0 AND
	   @bConvention_Fermee = 0 AND
	   @bRempl_Benef_Non_Reconnu = 0 AND
	   @bTransfert_Non_Autorise = 0 AND
	   @bRetrait_Premature = 0
		BEGIN
			-- Calculer le montant du PAE
			-----------------------------
			SELECT @mMontant_PAE = ISNULL(SUM(ConventionOperAmount),0)
			FROM Un_ConventionOper CO
			WHERE CO.OperID = @iID_Operation
			  AND CO.ConventionOperTypeID NOT IN ('BRS','AVC','RTN','RST')

			SELECT @mMontant_PAE = @mMontant_PAE+ISNULL(SUM(fCESG),0)+ISNULL(SUM(fACESG),0)+ISNULL(SUM(fCLB),0)+ISNULL(SUM(fPG),0)
			FROM Un_CESP C
			WHERE C.OperID = @iID_Operation

			SET @mMontant_PAE = @mMontant_PAE*-1

			-- Calculer la JVM (sans l’IQÉÉ, sans les cotisations, sans la bourse)
			----------------------------------------------------------------------

			-- Calculer les soldes du BEC, subvention canadienne et programmes autres provinces
			SELECT @mBEC = ISNULL(SUM(C.fCLB),0),
				   @mSubvention_Canadienne = ISNULL(SUM(C.fCESG+C.fACESG),0),
				   @mProgrammes_Autres_Provinces = ISNULL(SUM(C.fPG),0)
			FROM Un_CESP C
				 JOIN Un_Oper O ON O.OperID = C.OperID
							   AND O.OperID < @iID_Operation
			WHERE C.ConventionID = @iID_Convention

			-- Déterminer le montant des revenus accumulés dans la convention
			SELECT @mJuste_Valeur_Marchande = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND O.OperID < @iID_Operation
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID IN ('IBC','INM','INS','IS+','IST','ITR')

			-- Calculer la juste valeur marchande
			SET @mJVM = @mJuste_Valeur_Marchande + @mBEC + @mSubvention_Canadienne + @mProgrammes_Autres_Provinces

			-- Calculer le pourcentage du PAE
			---------------------------------
			IF @mJVM = 0
				SET @fPourcentage_PAE = 0
			ELSE
				SET @fPourcentage_PAE = @mMontant_PAE / @mJVM
  
			-- Calculer les réponses de l'IQÉÉ (désuet depuis janvier 2010)
			---------------------------------------------------------------
			SELECT @mReponse_Credit_Base = ISNULL(SUM(RD.mMontant),0)
			FROM tblIQEE_Demandes D
				 JOIN tblIQEE_ReponsesDemande RD ON RD.iID_Demande_IQEE = D.iID_Demande_IQEE
				 JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
											 AND TR.vcCode = 'CDB'
			WHERE D.iID_Convention = @iID_Convention
	
			SELECT @mReponse_Majoration = ISNULL(SUM(RD.mMontant),0)
			FROM tblIQEE_Demandes D
				 JOIN tblIQEE_ReponsesDemande RD ON RD.iID_Demande_IQEE = D.iID_Demande_IQEE
				 JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
											 AND TR.vcCode = 'MAJ'
			WHERE D.iID_Convention = @iID_Convention
	
			SELECT @mReponse_Interets_RQ = ISNULL(SUM(RD.mMontant),0)
			FROM tblIQEE_Demandes D
				 JOIN tblIQEE_ReponsesDemande RD ON RD.iID_Demande_IQEE = D.iID_Demande_IQEE
				 JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
											 AND TR.vcCode = 'INT'
			WHERE D.iID_Convention = @iID_Convention

			-- Calculer les montants d'IQÉÉ déjà payés par chèque (désuet depuis janvier 2010)
			----------------------------------------------------------------------------------
--			SELECT @mCredit_Base_Deja_Verse = ISNULL(SUM(ISNULL(TMP.mCredit_Base_Verse,0)),0),
--				   @mMajoration_Deja_Verse = ISNULL(SUM(ISNULL(TMP.mMajoration_Verse,0)),0),
--				   @mInterets_RQ_Deja_Verse = ISNULL(SUM(ISNULL(TMP.mInterets_RQ_Verse,0)),0)
--			FROM [dbo].[tblTEMP_InformationsIQEEPourPAE] TMP
--				 JOIN Un_Oper O2 ON O2.OperID = TMP.iID_Operation
--				 JOIN CHQ_Operation O ON O.iOperationID = TMP.iID_Operation_Cheque
--									 AND O.bStatus = 0
--			WHERE TMP.iID_Convention = @iID_Convention
--			  AND TMP.mCredit_Base_Verse >= 0
--			  AND TMP.mMajoration_Verse >= 0
--			  AND TMP.mInterets_RQ_Verse >= 0

			-- Calculer les soldes de l'IQÉÉ (en vigueur depuis janvier 2010
			----------------------------------------------------------------
			SET @mSolde_Credit_Base = 0
			SET @mSolde_Majoration = 0
			SET @mSolde_Interets_RQ = 0
			SET @mSolde_Interets_IQI = 0
			SET @mSolde_Interets_ICQ = 0
			SET @mSolde_Interets_IMQ = 0
			SET @mSolde_Interets_IIQ = 0
			SET @mSolde_Interets_III = 0

			SELECT @mSolde_Credit_Base = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND (O.OperTypeID <> 'IQE'
									OR (O.OperTypeID = 'IQE' AND O.OperDate <= GETDATE()))
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID = 'CBQ'

			SELECT @mSolde_Majoration = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND (O.OperTypeID <> 'IQE'
									OR (O.OperTypeID = 'IQE' AND O.OperDate <= GETDATE()))
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID = 'MMQ'

			SELECT @mSolde_Interets_RQ = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND (O.OperTypeID <> 'IQE'
									OR (O.OperTypeID = 'IQE' AND O.OperDate <= GETDATE()))
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID = 'MIM'

			SELECT @mSolde_Interets_IQI = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND (O.OperTypeID <> 'IQE'
									OR (O.OperTypeID = 'IQE' AND O.OperDate <= GETDATE()))
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID = 'IQI'

			SELECT @mSolde_Interets_ICQ = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND (O.OperTypeID <> 'IQE'
									OR (O.OperTypeID = 'IQE' AND O.OperDate <= GETDATE()))
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID = 'ICQ'

			SELECT @mSolde_Interets_IMQ = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND (O.OperTypeID <> 'IQE'
									OR (O.OperTypeID = 'IQE' AND O.OperDate <= GETDATE()))
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID = 'IMQ'

			SELECT @mSolde_Interets_IIQ = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND (O.OperTypeID <> 'IQE'
									OR (O.OperTypeID = 'IQE' AND O.OperDate <= GETDATE()))
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID = 'IIQ'

			SELECT @mSolde_Interets_III = ISNULL(SUM(CO.ConventionOperAmount),0)
			FROM Un_ConventionOper CO
				 JOIN Un_Oper O ON O.OperID = CO.OperID
							   AND (O.OperTypeID <> 'IQE'
									OR (O.OperTypeID = 'IQE' AND O.OperDate <= GETDATE()))
			WHERE CO.ConventionID = @iID_Convention
			  AND CO.ConventionOperTypeID = 'III'

			-- Mesure de contrôle
			IF @mMontant_PAE < 0 OR
			   @mJVM < 0 OR
			   @fPourcentage_PAE < 0 OR
			   @fPourcentage_PAE > 1 OR
--			   @mReponse_Credit_Base < 0 OR
--			   @mReponse_Majoration < 0 OR
--			   @mReponse_Interets_RQ < 0 OR
--			   @mCredit_Base_Deja_Verse < 0 OR
--			   @mMajoration_Deja_Verse < 0 OR
--			   @mInterets_RQ_Deja_Verse < 0 OR
--			   @mCredit_Base_Deja_Verse > @mReponse_Credit_Base OR
--			   @mMajoration_Deja_Verse > @mReponse_Majoration OR
--			   @mInterets_RQ_Deja_Verse > @mReponse_Interets_RQ
			   @mSolde_Credit_Base < 0 OR
			   @mSolde_Majoration < 0 OR
			   @mSolde_Interets_RQ < 0 OR
			   @mSolde_Interets_IQI < 0 OR
			   @mSolde_Interets_ICQ < 0 OR
			   @mSolde_Interets_IMQ < 0 OR
			   @mSolde_Interets_IIQ < 0 OR
			   @mSolde_Interets_III < 0
				BEGIN
					-- Appliquer 0
					SET @mCredit_Base_Verse = 0
					SET @mMajoration_Verse = 0
					SET @mInterets_RQ_Verse = 0
					SET @mInterets_IQI_Verse = 0
					SET @mInterets_ICQ_Verse = 0
					SET @mInterets_IMQ_Verse = 0
					SET @mInterets_IIQ_Verse = 0
					SET @mInterets_III_Verse = 0
				END
			ELSE
				BEGIN
					-- Payer l'IQÉÉ et les intérêts de l'IQÉÉ selon le pourcentage du PAE
					SET @mCredit_Base_Verse = ROUND(@mSolde_Credit_Base * @fPourcentage_PAE,2)
					SET @mMajoration_Verse = ROUND(@mSolde_Majoration * @fPourcentage_PAE,2)
					SET @mInterets_RQ_Verse = ROUND(@mSolde_Interets_RQ * @fPourcentage_PAE,2)
					SET @mInterets_IQI_Verse = ROUND(@mSolde_Interets_IQI * @fPourcentage_PAE,2)
					SET @mInterets_ICQ_Verse = ROUND(@mSolde_Interets_ICQ * @fPourcentage_PAE,2)
					SET @mInterets_IMQ_Verse = ROUND(@mSolde_Interets_IMQ * @fPourcentage_PAE,2)
					SET @mInterets_IIQ_Verse = ROUND(@mSolde_Interets_IIQ * @fPourcentage_PAE,2)
					SET @mInterets_III_Verse = ROUND(@mSolde_Interets_III * @fPourcentage_PAE,2)

					-- Insérer les transactions dans l'opération de PAE
					IF @mCredit_Base_Verse > 0
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
							   (@iID_Operation
							   ,@iID_Convention
							   ,'CBQ'
							   ,@mCredit_Base_Verse*-1)

					IF @mMajoration_Verse > 0
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
							   (@iID_Operation
							   ,@iID_Convention
							   ,'MMQ'
							   ,@mMajoration_Verse*-1)

					IF @mInterets_RQ_Verse > 0
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
							   (@iID_Operation
							   ,@iID_Convention
							   ,'MIM'
							   ,@mInterets_RQ_Verse*-1)

					IF @mInterets_IQI_Verse > 0
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
							   (@iID_Operation
							   ,@iID_Convention
							   ,'IQI'
							   ,@mInterets_IQI_Verse*-1)

					IF @mInterets_ICQ_Verse > 0
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
							   (@iID_Operation
							   ,@iID_Convention
							   ,'ICQ'
							   ,@mInterets_ICQ_Verse*-1)

					IF @mInterets_IMQ_Verse > 0
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
							   (@iID_Operation
							   ,@iID_Convention
							   ,'IMQ'
							   ,@mInterets_IMQ_Verse*-1)

					IF @mInterets_IIQ_Verse > 0
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
							   (@iID_Operation
							   ,@iID_Convention
							   ,'IIQ'
							   ,@mInterets_IIQ_Verse*-1)

					IF @mInterets_III_Verse > 0
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
							   (@iID_Operation
							   ,@iID_Convention
							   ,'III'
							   ,@mInterets_III_Verse*-1)
				END
		END

	------------------------------------------------
	-- Enregistrer les informations de l'IQÉÉ du PAE
	------------------------------------------------
	INSERT INTO [dbo].[tblTEMP_InformationsIQEEPourPAE]
			   ([iID_Convention]
			   ,[iID_Operation]
			   ,[iID_Operation_Cheque]
			   ,[dtDate]
			   ,[bPAE_Destine_Beneficiaire]
			   ,[bBeneficiare_Quebec]
			   ,[bConvention_Rejetee]
			   ,[bConvention_Fermee]
			   ,[bRempl_Benef_Non_Reconnu]
			   ,[bTransfert_Non_Autorise]
			   ,[bRetrait_Premature]
			   ,[mMontant_PAE]
			   ,[mJVM]
			   ,[fPourcentage_PAE]
			   ,[mReponse_Credit_Base]
			   ,[mReponse_Majoration]
			   ,[mReponse_Interets_RQ]
			   ,[mCredit_Base_Deja_Verse]
			   ,[mMajoration_Deja_Verse]
			   ,[mInterets_RQ_Deja_Verse]
			   ,[mCredit_Base_Verse]
			   ,[mMajoration_Verse]
			   ,[mInterets_RQ_Verse]
			   ,mSolde_Credit_Base
			   ,mSolde_Majoration
			   ,mSolde_Interets_RQ
			   ,mSolde_Interets_IQI
			   ,mSolde_Interets_ICQ
			   ,mSolde_Interets_IMQ
			   ,mSolde_Interets_IIQ
			   ,mSolde_Interets_III
			   ,mInterets_IQI_Verse
			   ,mInterets_ICQ_Verse
			   ,mInterets_IMQ_Verse
			   ,mInterets_IIQ_Verse
			   ,mInterets_III_Verse)
		 VALUES
			   (@iID_Convention
			   ,@iID_Operation
			   ,@iID_Operation_Cheque
			   ,GETDATE()
			   ,@bPAE_Destine_Beneficiaire
			   ,@bBeneficiare_Quebec
			   ,@bConvention_Rejetee
			   ,@bConvention_Fermee
			   ,@bRempl_Benef_Non_Reconnu
			   ,@bTransfert_Non_Autorise
			   ,@bRetrait_Premature
			   ,@mMontant_PAE
			   ,@mJVM
			   ,@fPourcentage_PAE
			   ,@mReponse_Credit_Base
			   ,@mReponse_Majoration
			   ,@mReponse_Interets_RQ
			   ,@mCredit_Base_Deja_Verse
			   ,@mMajoration_Deja_Verse
			   ,@mInterets_RQ_Deja_Verse
			   ,@mCredit_Base_Verse
			   ,@mMajoration_Verse
			   ,@mInterets_RQ_Verse
			   ,@mSolde_Credit_Base
			   ,@mSolde_Majoration
			   ,@mSolde_Interets_RQ
			   ,@mSolde_Interets_IQI
			   ,@mSolde_Interets_ICQ
			   ,@mSolde_Interets_IMQ
			   ,@mSolde_Interets_IIQ
			   ,@mSolde_Interets_III
			   ,@mInterets_IQI_Verse
			   ,@mInterets_ICQ_Verse
			   ,@mInterets_IMQ_Verse
			   ,@mInterets_IIQ_Verse
			   ,@mInterets_III_Verse)
	IF @@ERROR <> 0
		SET @iID_IQEE_PAE = 0
	ELSE
		SET @iID_IQEE_PAE = SCOPE_IDENTITY()

	-- Retourner l'identifiant des informations
	RETURN @iID_IQEE_PAE
END