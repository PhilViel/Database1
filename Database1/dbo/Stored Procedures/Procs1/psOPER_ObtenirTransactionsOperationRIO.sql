/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_ObtenirTransactionsOperationRIO
Nom du service		:		Obtenir les transaction d'une operation RIO
But					:		Obtenir toutes les informations transactions relatives à une opération RIO.
							
Facette				:		OPER
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iID_Oper_RIO			Identifiant de l'operation RIO à consulter

Exemple d'appel:
				EXECUTE dbo.psOPER_ObtenirTransactionsOperationRIO 17349210 
				
				@iID_Oper_RIO = 17184380, --ID de l'opération RIO à consulter

				resultats:
				type transaction :  1173353 -> 1992-11-01 (1.50)
									1173353 -> 2008-06-20 (1.00)
				Beneficiaire : Bellemare, Keven
				Souscripteur : Pineault, Christine
				
				EXECUTE dbo.psOPER_ObtenirTransactionsOperationRIO 19506702
				EXECUTE	dbo.psOPER_ObtenirTransactionsOperationRIO 20285236

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													@vcDescTransaction					Description de la transaction.selon :
																						si c’est une cotisation :
																							[Un_Convention.ConventionNo] + “ -> “ + [Un_Unit.InForceDate] + “ (“ + [Un_Unit.UnitQty] + “)“
																						si c’est une transaction sur la convention ou sur la subvention canadienne : 
																							[Un_Convention.ConventionNo]
						Un_Cotisation				Co.Cotisation(Cotisation)			Montant des épargnes.  
													Co.Fee(Fee)							Montant des frais.
						Un_ConventionOper			Cop.ConventionOperAmount			 selon le type de transaction  :
													(ConventionOperAmount)					- INM (Montant d’intérêts sur le montant souscrit)
																							- ITR (Montant d’intérêts provenant d’un transfert IN)
																							- IST (Montant d’intérêts sur la subvention canadienne provenant d’un transfert IN)
																							- INS (Montant d’intérêts sur la subvention canadienne)
																							- IS+ (Montant d’intérêts sur la subvention canadienne bonifiée)
																							- IBC (Montant d’intérêts sur le BEC)
																							- mIQEE				: Montant du crédit de base : catégorie	OPER_MONTANTS_CREDITBASE (Type CBQ)
																							- mRend_IQEE		: Montant d'intérets sur le crédit de base : catégorie OPER_MONTANTS_RENDEMENTS_CREDITBASE (Type ICQ, MIM, IIQ)
																							- mIQEE_Plus		: Montant majoré : catégorie OPER_MONTANTS_MAJORATION (Type MMQ)
																							- mRend_IQEE_Plus	: Montant d'intérêt sur le montant majoré : catégorie OPER_MONTANTS_RENDEMENTS_MAJORATION (Type IMQ) 
																							- mRend_IQEE_TIN	: Montant d'intérêt sur le transfert IN : catégorie OPER_MONTANTS_RENDEMENTS_IQEE_TIN (Type III, IQI) 

						Un_CESP						Ces.fCESG(fCESG)
													Ces.fACESG(fACESG)													
													Ces.fCLB(fCLB)
													Ces.fPG(fPG)
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-06-19					Nassim Rekkab							Création de procédure stockée
						2010-05-07					Jean-François Gauthier				Ajout de la gestion des erreurs
						2010-12-20					Jean-François Gauthier				Ajout des champs mIQEE, mRend_IQEE, mIQEE_Plus, mRend_IQEE_Plus, mRend_IQEE_TIN
																											Correction de la structure des requêtes
						2011-01-12					Jean-François Gauthier				Correction des montants IQEE retournés 
						2011-04-12					Frédérick Thibault						Ajout des champs d'intérêts sur RIM ou TRI
						2014-10-07					Pierre-Luc Simard						Correction du dédoublement des montants lorsque plusieurs opérations sur une même convention
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirTransactionsOperationRIO] (

	@iID_Oper_RIO INTEGER 
)
AS
	BEGIN		
		BEGIN TRY
			SELECT 
				 vcTransacType
				,ConventionID
				,ConventionNo
				,UnitID
				,InForceDate
				,UnitQty
				,SubscriberName
				,BeneficiaryName
				,mEpargne
				,mFrais
				,mINTMONTSOUSCRIT
				,mEAFB	-- FT1
				,mRENDIND	-- FT1
				,mINTTIN
				,mINTPCEETIN
				,mINTSCEE
				,mINTSCEEPLUS
				,mINTBEC
				,mSCEE
				,mSCEEPLUS
				,mBEC
				,mfPG
				,mIQEE
				,mRend_IQEE
				,mIQEE_Plus
				,mRend_IQEE_Plus
				,mRend_IQEE_TIN		-- ajout JFG : 2010-12-20
			FROM
			--Union des transactions
			(
			SELECT (Conv.ConventionNo  + ' -> ' + (CAST(YEAR(U.InForceDate) AS VARCHAR) 
					+ '-' + (CASE WHEN MONTH(U.InForceDate) < 10 THEN '0' + CAST(MONTH(U.InForceDate) AS VARCHAR) ELSE CAST(MONTH(U.InForceDate) AS VARCHAR) END) 
					+ '-' + (CASE WHEN  DAY(U.InForceDate) < 10 THEN '0' + CAST(DAY(U.InForceDate) AS VARCHAR) ELSE CAST(DAY(U.InForceDate) AS VARCHAR) END))  + ' (' + CAST(CAST(U.UnitQty AS DECIMAL(6,3)) AS VARCHAR) + ')') AS vcTransacType
					,Conv.ConventionID
					,Conv.ConventionNo
					,U.UnitID
					,U.InForceDate
					,U.UnitQty
					,SubscriberName = 
									CASE 
										WHEN S.IsCompany = 1 THEN S.LastName
									ELSE S.LastName+', '+S.FirstName
									END
					,BeneficiaryName = B.LastName + ', ' + B.FirstName
					,Co.Cotisation	as mEpargne
					,Co.Fee			as mFrais
					,NULL			as mINTMONTSOUSCRIT
					
					,NULL			AS mEAFB	-- FT1
					,NULL			AS mRENDIND	-- FT1
					
					,NULL			as mINTTIN
					,NULL			as mINTPCEETIN
					,NULL			as mINTSCEE
					,NULL			as mINTSCEEPLUS
					,NULL			as mINTBEC
					,NULL			as mSCEE
					,NULL			as mSCEEPLUS
					,NULL			as mBEC
					,NULL			as mfPG
					,NULL			AS mIQEE
					,NULL			AS mRend_IQEE
					,NULL			AS mIQEE_Plus
					,NULL			AS mRend_IQEE_Plus
					,NULL			AS mRend_IQEE_TIN 
			FROM 
				dbo.Un_Cotisation Co
				INNER JOIN dbo.Un_Unit U 
					ON (Co.UnitID = U.UnitID)
				INNER JOIN dbo.Un_Convention Conv 
					ON (U.ConventionID = Conv.ConventionID)		
				INNER JOIN dbo.Mo_Human S 
					ON (S.HumanID = Conv.SubscriberID)
				INNER JOIN dbo.Mo_Human B 
					ON (B.HumanID = Conv.BeneficiaryID)
			WHERE 
				Co.operID = @iID_Oper_RIO

		UNION ALL
			--convention source
			SELECT	 CON.ConventionNo
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,SUM(OP1.ConventionOperAmount)AS mINTMONTSOUSCRIT
					
					,RND.RendInd *-1	AS mEAFB	-- FT1
					,NULL				AS mRENDIND	-- FT1
					
					,SUM(OP2.ConventionOperAmount)AS mINTTIN
					,SUM(OP3.ConventionOperAmount)AS mINTPCEETIN
					,SUM(OP4.ConventionOperAmount)AS mINTSCEE
					,SUM(OP5.ConventionOperAmount)AS mINTSCEEPLUS
					,SUM(OP6.ConventionOperAmount)AS mINTBEC
					,SUM(Ces.fCESG)
					,SUM(Ces.fACESG)
					,SUM(Ces.fCLB)
					,SUM(Ces.fPG)
					,mIQEE				= (	SELECT	SUM(OP7.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP7 WHERE (OpRIO.iID_Oper_RIO = OP7.OperID AND OP7.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE') fct WHERE fct.cID_Type_Oper_Convention = OP7.ConventionOperTypeID)))
					,mRend_IQEE			= (	SELECT	SUM(OP8.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP8 WHERE (OpRIO.iID_Oper_RIO = OP8.OperID AND OP8.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_RENDEMENTS_CREDITBASE') fct WHERE fct.cID_Type_Oper_Convention = OP8.ConventionOperTypeID)))
					,mIQEE_Plus			= (	SELECT	SUM(OP9.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP9 WHERE (OpRIO.iID_Oper_RIO = OP9.OperID AND OP9.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION') fct WHERE fct.cID_Type_Oper_Convention = OP9.ConventionOperTypeID)))
					,mRend_IQEE_Plus	= ( SELECT	SUM(OP10.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP10 WHERE (OpRIO.iID_Oper_RIO = OP10.OperID AND OP10.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_RENDEMENTS_MAJORATION') fct WHERE fct.cID_Type_Oper_Convention = OP10.ConventionOperTypeID)))
					,mRend_IQEE_TIN		= ( SELECT	SUM(OP11.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP11 WHERE (OpRIO.iID_Oper_RIO = OP11.OperID AND OP11.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_RENDEMENTS_IQEE_TIN') fct WHERE fct.cID_Type_Oper_Convention = OP11.ConventionOperTypeID)))
			FROM 
				dbo.tblOPER_OperationsRIO OpRIO
				INNER JOIN dbo.Un_Convention CON 
					ON OpRIO.iID_Convention_Source = CON.ConventionID
				LEFT OUTER JOIN Un_ConventionOper OP1 
					ON (OpRIO.iID_Oper_RIO = OP1.OperID AND OP1.ConventionID = CON.ConventionID AND OP1.ConventionOperTypeID = 'INM')
				LEFT OUTER JOIN Un_ConventionOper OP2 
					ON (OpRIO.iID_Oper_RIO = OP2.OperID AND OP2.ConventionID = CON.ConventionID AND	OP2.ConventionOperTypeID = 'ITR')
				LEFT OUTER JOIN Un_ConventionOper OP3 
					ON (OpRIO.iID_Oper_RIO = OP3.OperID AND OP3.ConventionID = CON.ConventionID AND OP3.ConventionOperTypeID = 'IST')
				LEFT OUTER JOIN Un_ConventionOper OP4 
					ON (OpRIO.iID_Oper_RIO = OP4.OperID AND OP4.ConventionID = CON.ConventionID AND OP4.ConventionOperTypeID = 'INS')
				LEFT OUTER JOIN Un_ConventionOper OP5 
					ON (OpRIO.iID_Oper_RIO = OP5.OperID AND OP5.ConventionID = CON.ConventionID AND OP5.ConventionOperTypeID = 'IS+')
				LEFT OUTER JOIN Un_ConventionOper OP6 
					ON (OpRIO.iID_Oper_RIO = OP6.OperID AND OP6.ConventionID = CON.ConventionID AND OP6.ConventionOperTypeID = 'BEC')
				LEFT OUTER JOIN Un_CESP Ces 
					ON (Ces.OperID = OpRIO.iID_Oper_RIO AND Ces.ConventionID = CON.ConventionID)
				LEFT JOIN ( -- Recherche des intérêts sur individuelle générés après RIM ou TRI - FT1
					SELECT
						 ConventionID	= CO.ConventionID
						,RendInd		= CO.ConventionOperAmount
						,iID_Convention_Source = RIO.iID_Convention_Source
					FROM Un_ConventionOper CO
					JOIN tblOPER_OperationsRIO RIO ON RIO.iID_Convention_Destination = CO.ConventionID
															AND RIO.iID_Oper_RIO = @iID_Oper_RIO
					JOIN Un_Oper OP ON OP.OperID = CO.OperID
					JOIN tblOPER_AssociationOperations AO1	ON	AO1.iID_Operation_Enfant = OP.OperID 
															AND	AO1.iID_Operation_Parent = @iID_Oper_RIO
															AND	CO.ConventionOperTypeID = 'INM'
					) RND ON RND.ConventionID = OpRIO.iID_Convention_Destination

			WHERE 
				OpRIO.iID_OPER_RIO = @iID_Oper_RIO
			GROUP BY 
				CON.ConventionNo,
				CON.ConventionID, 
				OpRIO.iID_Oper_RIO,
				RND.RendInd -- FT1
		
		UNION ALL
			--convention destination
			SELECT	 CON.ConventionNo
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,NULL
					,SUM(OP1.ConventionOperAmount)
					
					,NULL			AS mEAFB	-- FT1
					,RND.RendInd	AS mRENDIND	-- FT1
					
					,SUM(OP2.ConventionOperAmount)
					,SUM(OP3.ConventionOperAmount)
					,SUM(OP4.ConventionOperAmount)
					,SUM(OP5.ConventionOperAmount)
					,SUM(OP6.ConventionOperAmount)
					,SUM(Ces.fCESG)
					,SUM(Ces.fACESG)
					,SUM(Ces.fCLB)
					,SUM(Ces.fPG)
					,mIQEE				= (	SELECT	SUM(OP7.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP7 WHERE (OpRIO.iID_Oper_RIO = OP7.OperID AND OP7.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE') fct WHERE fct.cID_Type_Oper_Convention = OP7.ConventionOperTypeID)))
					,mRend_IQEE			= (	SELECT	SUM(OP8.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP8 WHERE (OpRIO.iID_Oper_RIO = OP8.OperID AND OP8.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_RENDEMENTS_CREDITBASE') fct WHERE fct.cID_Type_Oper_Convention = OP8.ConventionOperTypeID)))
					,mIQEE_Plus			= (	SELECT	SUM(OP9.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP9 WHERE (OpRIO.iID_Oper_RIO = OP9.OperID AND OP9.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION') fct WHERE fct.cID_Type_Oper_Convention = OP9.ConventionOperTypeID)))
					,mRend_IQEE_Plus	= ( SELECT	SUM(OP10.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP10 WHERE (OpRIO.iID_Oper_RIO = OP10.OperID AND OP10.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_RENDEMENTS_MAJORATION') fct WHERE fct.cID_Type_Oper_Convention = OP10.ConventionOperTypeID)))
					,mRend_IQEE_TIN		= ( SELECT	SUM(OP11.ConventionOperAmount) FROM	dbo.Un_ConventionOper OP11 WHERE (OpRIO.iID_Oper_RIO = OP11.OperID AND OP11.ConventionID = CON.ConventionID AND EXISTS(	SELECT 1 FROM dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_RENDEMENTS_IQEE_TIN') fct WHERE fct.cID_Type_Oper_Convention = OP11.ConventionOperTypeID)))
			FROM 
				dbo.tblOPER_OperationsRIO OpRIO
				INNER JOIN dbo.Un_Convention CON 
					ON OpRIO.iID_Convention_Destination = CON.ConventionID
				LEFT OUTER JOIN Un_ConventionOper OP1 
					ON (OpRIO.iID_Oper_RIO = OP1.OperID	AND OP1.ConventionID = CON.ConventionID AND OP1.ConventionOperTypeID = 'INM')
				LEFT OUTER JOIN Un_ConventionOper OP2 
					ON (OpRIO.iID_Oper_RIO = OP2.OperID AND OP2.ConventionID = CON.ConventionID AND	OP2.ConventionOperTypeID = 'ITR')
				LEFT OUTER JOIN Un_ConventionOper OP3 
					ON (OpRIO.iID_Oper_RIO = OP3.OperID AND OP3.ConventionID = CON.ConventionID AND OP3.ConventionOperTypeID = 'IST')
				LEFT OUTER JOIN Un_ConventionOper OP4 
					ON (OpRIO.iID_Oper_RIO = OP4.OperID AND OP4.ConventionID = CON.ConventionID AND OP4.ConventionOperTypeID = 'INS')
				LEFT OUTER JOIN Un_ConventionOper OP5 
					ON (OpRIO.iID_Oper_RIO = OP5.OperID AND OP5.ConventionID = CON.ConventionID AND OP5.ConventionOperTypeID = 'IS+')
				LEFT OUTER JOIN Un_ConventionOper OP6 
					ON (OpRIO.iID_Oper_RIO = OP6.OperID AND OP6.ConventionID = CON.ConventionID AND OP6.ConventionOperTypeID = 'BEC')
				LEFT OUTER JOIN Un_CESP Ces 
					ON (Ces.OperID = OpRIO.iID_Oper_RIO AND Ces.ConventionID = CON.ConventionID)
				LEFT JOIN ( -- Recherche des intérêts sur individuelle générés après RIM ou TRI - FT1
					SELECT
						 ConventionID	= CO.ConventionID
						,RendInd		= CO.ConventionOperAmount
					FROM Un_ConventionOper CO
					JOIN Un_Oper OP ON OP.OperID = CO.OperID
					JOIN tblOPER_AssociationOperations AO1	ON	AO1.iID_Operation_Enfant = OP.OperID 
															AND	AO1.iID_Operation_Parent = @iID_Oper_RIO
					AND		CO.ConventionOperTypeID = 'INM'
					) RND ON RND.ConventionID = OpRIO.iID_Convention_Destination
			WHERE 
				OpRIO.iID_OPER_RIO = @iID_Oper_RIO
			GROUP BY 
				CON.ConventionNo,
				CON.ConventionID, 
				OpRIO.iID_Oper_RIO,
				RND.RendInd -- FT1
				) AS S1
			WHERE 
				(
				ISNULL(mEpargne,0) <> 0 
				OR ISNULL(mFrais,0) <> 0 
				OR ISNULL(mINTMONTSOUSCRIT,0) <> 0 
				OR ISNULL(mINTTIN,0) <> 0 
				OR ISNULL(mINTPCEETIN,0) <> 0 
				OR ISNULL(mINTSCEE,0) <> 0 
				OR ISNULL(mINTSCEEPLUS,0) <> 0 
				OR ISNULL(mINTBEC,0) <> 0 
				OR ISNULL(mSCEE,0) <> 0 
				OR ISNULL(mSCEEPLUS,0) <> 0 
				OR ISNULL(mBEC,0) <> 0 
				OR ISNULL(mfPG,0) <> 0
				OR ISNULL(mIQEE,0) <> 0
				OR ISNULL(mRend_IQEE,0) <> 0
				OR ISNULL(mIQEE_Plus,0) <> 0
				OR ISNULL(mRend_IQEE_Plus,0) <> 0
				OR ISNULL(mRend_IQEE_TIN,0) <> 0
				)
		END TRY
		BEGIN CATCH
			DECLARE		 
				@iErrSeverite	INT
				,@iErrStatut	INT
				,@vcErrMsg		NVARCHAR(1024)
				
			SELECT
				@vcErrMsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
				,@iErrStatut	= ERROR_STATE()
				,@iErrSeverite	= ERROR_SEVERITY()
	
			RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
		END CATCH
	END


