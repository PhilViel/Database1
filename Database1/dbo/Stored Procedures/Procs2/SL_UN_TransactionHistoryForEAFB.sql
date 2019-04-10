/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_TransactionHistoryForEAFB
Description         :	Historique des EAFB
Valeurs de retours  : 
Exemple d'appel		:	
						EXECUTE dbo.SL_UN_TransactionHistoryForEAFB 'CNV', 127680
						EXECUTE dbo.SL_UN_TransactionHistoryForEAFB 'CNV', 337388
						EXECUTE dbo.SL_UN_TransactionHistoryForEAFB 'BEN', 253513

Note                :	ADX0000601	IA	2004-12-17	Bruno Lapointe			Création
								ADX0001237	BR	2004-01-19	Bruno Lapointe			Retour du status de l'opération
								ADX0001289	BR	2005-02-17	Bruno Lapointe			Retour du détail du chèque
								ADX0000753	IA	2005-11-03	Bruno Lapointe			Changer les valeurs de retours +HaveCheque, -ChequeID, -ChequeNo, -ChequeDate, 
																						-ChequeOrderID, -ChequeOrderDate, 
																						-ChequeOrderDesc, -ChequeName, -ChequeAmount
								ADX0000997 	IA	2006-05-12	Alain Quirion
								ADX0002426	BR	2007-05-22	Bruno Lapointe			Création de la table Un_CESP.
												2009-04-03	Pierre-Luc Simard		supprimer les doublons da la table SpecialOperView
												2009-12-10	Jean-François Gauthier	Modification des INT pour IN+ et IN-
												2009-12-17	Jean-François Gauthier	Modification pour intégrer OPER_RENDEMENT_POSITIF_NEGATIF
																					Ajout du Group by par catégories d'opération
												2009-12-21  Rémy Rouillard			Ajout d'une colonne et suppression des transaction RIN
												2009-12-22  Rémy Rouillard			Afficher les transactions RIN lorsque ces dernières touche
																					la table un_ConventionOper 
												2010-01-05	Jean-François Gauthier	Réactivation du CASE dans le Groupe By pour OperID
												2010-01-15	Jean-François Gauthier	Remplacement de fnOPER_ObtenirTypesOperationConvCategorie par fnOPER_ObtenirTypesOperationCategorie
												2010-01-19	Rémy Rouillard			Ajout d'un appel à la catégorie OPER_TYPE_CONV_HISTO_EAFB 
												2010-01-20	Jean-François Gauthier	Correction pour le IntRI
												2010-01-21	Jean-François Gauthier	Intégration modif. Rémy Rouillard
												2010-05-10  Pierre Paquet			Exlure les transferts à zéro.
												2010-06-07	Pierre Paquet			Correction: Tenir compte du Cotisation = 0.
												2010-06-10	Pierre Paquet			Mise en commentaire de l'exclusion des transferts à zéro.
												2011-04-01	Frédérick Thibault		Ajout des fonctionnalité du prospectus 2010-2011 (FT1)
												2011-11-16	Christian Chénard		Modification du "Group by O.OperID" en plaçant la construction de la liste des types d'opération en-dehors de la requête
												2014-09-24	Donald Huppé			Modification pour les DDD : on passe le operid dans le champ iOperationID.
												2015-03-13	Donald Huppé			glpi 13758 : Ajout du PlanOper associé à une bourse
												2016-04-21	Pierre-Luc Simard	    OperType à 5 caractères lors de l'appel de la procédure SL_UN_TransactionHistoryForCS (Parenthèses pour les annulations de FRM)
                                                2017-02-17  Pierre-Luc Simard       Correction du tri par date et par OperID
                                                2017-12-12  Pierre-Luc Simard       Ajout du compte RST dans le compte BRS
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_TransactionHistoryForEAFB] 
						(
						@Type	VARCHAR(3), -- Type d'historique (convention 'CNV', bénéficiaire 'BEN')
						@ID		INT			-- Id de l’objet (ConventionID ou BeneficiaryID).	
						)
AS						
BEGIN
	-- Christian Chénard (2011-11-16) 
	-- La liste doit être construite en-dehors de la requête principale
	DECLARE @TypesOperCat VARCHAR(MAX)  
	SET @TypesOperCat = (SELECT dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_TRANSACTION_CONSULT_EAFB'))
	SET @TypesOperCat = substring(@TypesOperCat, 2,len(@TypesOperCat)-2)
	
	DECLARE 
		@vcOPER_RENDEMENT_POSITIF_NEGATIF VARCHAR(200)

	SET @vcOPER_RENDEMENT_POSITIF_NEGATIF = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_RENDEMENT_POSITIF_NEGATIF')

	-- 2010-01-13 : JFG :	Récupération des résultat de la procédure SL_UN_TransactionHistoryForCS
	--						afin de faire l'arrimage du OperTypeID pour les transactions OUT
	DECLARE @TransactionHistoryForCS TABLE
								(
									OperID			INT
									,OperDate		DATETIME
									,EffectDate		DATETIME
									,OperTypeID		VARCHAR(5)
									,CodeNSF		VARCHAR(3)
									,Total			MONEY
									,Cotisation		MONEY
									,Fee			MONEY
									,Ecart			MONEY
									,SubscInsur		MONEY
									,BenefInsur		MONEY	
									,TaxOnInsur		MONEY
									,Interests		MONEY

									,mMontant_Frais		MONEY	-- FT1
									,mMontant_TaxeTPS	MONEY	-- FT1
									,mMontant_TaxeTVQ	MONEY	-- FT1
									
									,LastReceiveDate DATETIME
									,fCESG			MONEY 
									,fACESG			MONEY 
									,fCLB			MONEY 
									,iOperationID	INT
									,HaveCheque		BIT
									,LockAccount	BIT
									,AnticipedCPA	BIT
									,OperTypeIDView	CHAR(3)
									,PlanTypeIDView	CHAR(3)
									,Status			INT
								)
								
	INSERT INTO @TransactionHistoryForCS
	(
		OperID			
		,OperDate		
		,EffectDate		
		,OperTypeID
		,CodeNSF			
		,Total			
		,Cotisation		
		,Fee				
		,Ecart			
		,SubscInsur		
		,BenefInsur		
		,TaxOnInsur		
		,Interests		

		,mMontant_Frais		-- FT1
		,mMontant_TaxeTPS	-- FT1
		,mMontant_TaxeTVQ	-- FT1

		,LastReceiveDate 
		,fCESG			
		,fACESG			
		,fCLB			
		,iOperationID	
		,HaveCheque		
		,LockAccount		
		,AnticipedCPA	
		,OperTypeIDView	
		,PlanTypeIDView	
		,Status			
	)
	EXECUTE dbo.SL_UN_TransactionHistoryForCS @Type, @ID

	-- Table qui donne les opérations spéciales dont la fenêtre de visualisation ne correspond pas précisément au OperTypeID Ex: TFR lié à une résiliation.
	CREATE TABLE #SpecialOperView 
		(
		OperID			INT PRIMARY KEY,
		OperTypeIDView CHAR(3)
		)

	INSERT INTO #SpecialOperView 
	(
		OperID,
		OperTypeIDView
	)
	SELECT DISTINCT
		O.OperID,
		'PAE'
	FROM 
		dbo.Un_Convention C
		INNER JOIN dbo.Un_ConventionOper CO 
			ON CO.ConventionID = C.ConventionID
		INNER JOIN dbo.Un_Oper O 
			ON O.OperID = CO.OperID
		INNER JOIN dbo.Un_ScholarshipPmt SP 
			ON SP.OperID = O.OperID
		INNER JOIN dbo.Un_ScholarshipPmt SP2 
			ON SP2.ScholarshipID = SP.ScholarshipID AND SP2.OperID <> SP.OperID
		INNER JOIN dbo.Un_Oper O2 
			ON O2.OperID = SP2.OperID
	WHERE 	
			O.OperTypeID = 'RGC'
			AND	O2.OperTypeID = 'PAE'
			AND	(	(		@Type = 'CNV'
						AND	C.ConventionID = @ID
						)
					OR	(		@Type = 'BEN'
						AND	C.BeneficiaryID = @ID
						)
					)
		
	SELECT
		OperID = CASE 
					WHEN ISNULL(SOV.OperTypeIDView, O.OperTypeID) NOT IN (SELECT val FROM	dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_TRANSACTION_CONSULT_EAFB'))) THEN NULL
					ELSE MAX(O.OperID)
				  END, 
		O.OperDate,
		O.OperTypeID,
		iOperationID = case when ddd.IdOperationFinanciere is not NULL or L.iOperationID is not null then
		
								CASE 
								WHEN ISNULL(SOV.OperTypeIDView, O.OperTypeID) NOT IN (SELECT val FROM	dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_TRANSACTION_CONSULT_EAFB'))) THEN NULL
								ELSE MAX(O.OperID)
								END
						else 0
						end, --ISNULL(L.iOperationID,0),
		HaveCheque = 
			CAST	(	
					CASE 
						WHEN Ch.OperID IS NULL and ddd.IdOperationFinanciere is null  THEN 0
					ELSE 1
					END AS BIT
					),
		IntClient = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'INC' THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
		IntEAFB = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'EFB' THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
		FraisDisp = 
			SUM(ISNULL(Ct.Fee,0)),
		Bourse = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') IN ('BRS', 'RST') THEN ISNULL(CO.ConventionOperAmount,0) + ISNULL(ScholarshipPmtDtlAmount,0) /*glpi 13758*/
				ELSE 0
				END
				),
		Avance = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'AVC' THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
/*		IntRI = 
			SUM(
				CASE
					WHEN	ISNULL(CO.ConventionOperTypeID,'') = 'INM' 
							AND 
							(O.OperTypeID IN 
								(dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_POSITIF'),dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_NEGATIF'))) 
							AND ISNULL(P.PlanTypeID,'') = 'COL' 
											THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
		IntIND = 
			SUM(
				CASE
					WHEN	ISNULL(CO.ConventionOperTypeID,'') = 'INM' 
							AND ((O.OperTypeID NOT IN 
									(dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_POSITIF'),dbo.fnOPER_ObtenirTypesOperationCategorie('OPER_RENDEMENT_NEGATIF'))) 
								OR ISNULL(P.PlanTypeID,'') <> 'COL') 
											THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				), */
		
		-- 2009-12-21 --> Modifié le PlanTypeId pour IND : fait par Rémy Rouillard
		-- Cette colonne correspond au REND. Ind section individuel
/*		IntIND = 
                  SUM(
                        CASE
                             WHEN ISNULL(CO.ConventionOperTypeID,'') = 'INM' AND (CHARINDEX(O.OperTypeID,@vcOPER_RENDEMENT_POSITIF_NEGATIF) = 0) AND ISNULL(P.PlanTypeID,'') = 'IND' THEN ISNULL(CO.ConventionOperAmount,0)
                        ELSE 0
                        END
                        ),*/
		-- 2009-12-21 --> Cette colonne correspond au REND. RI section collectif : fait par Rémy Rouillard
/*        IntRI = 
                  SUM(
                        CASE
                             WHEN ISNULL(CO.ConventionOperTypeID,'') = 'INM' AND ((CHARINDEX(O.OperTypeID,@vcOPER_RENDEMENT_POSITIF_NEGATIF) <> 0) AND ISNULL(P.PlanTypeID,'') = 'COL') THEN ISNULL(CO.ConventionOperAmount,0)
                        ELSE 0
                        END
                        ), */

		-- 2010-01-21 : Modif. Rémy
		IntIND = 
                  SUM(
                        CASE
                            WHEN ISNULL(CO.ConventionOperTypeID,'') = 'INM' AND ISNULL(P.PlanTypeID,'') = 'IND' THEN ISNULL(CO.ConventionOperAmount,0)                                    
                        ELSE 0
                        END
                        ),

        IntRI = 
                  SUM(
                        CASE
                            WHEN ISNULL(CO.ConventionOperTypeID,'') = 'INM' AND ISNULL(P.PlanTypeID,'') = 'COL' THEN ISNULL(CO.ConventionOperAmount,0) 
                        ELSE 0
                        END
                        ),
		-- 2009-12-21 --> Modifié le PlanTypeId pour COL : fait par Rémy Rouillard
		-- Cette colonne correspond au REND. TIN section Collectif
		IntTIN = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'ITR'	AND ISNULL(P.PlanTypeID,'') = 'COL'  THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
		-- 2009-12-21 --> Ajour de colonne pour le PlanTypeId IND : fait par Rémy Rouillard
		-- Cette colonne correspond au REND. TIN section Individuel
		IntTINInd = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'ITR'	AND ISNULL(P.PlanTypeID,'') = 'IND'  THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),

		-- Modification SCEE, IntSCEE et IntSCEETIN pour fCESG, fCESGInt, fCESGIntTIN ADX0000997
		fCESG = SUM(ISNULL(CE.fCESG,0)),
		fCESGInt = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'INS' THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
		fCESGIntTIN = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'IST' THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
		-- Ajout de fACESG, fACESGInt, fBEC, fBECInt ADX0000997
		fACESG = SUM(ISNULL(CE.fACESG,0)),	
		fACESGInt = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'IS+' THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
		fBEC = SUM(ISNULL(CE.fCLB,0)),	
		fBECInt = 
			SUM(
				CASE
					WHEN ISNULL(CO.ConventionOperTypeID,'') = 'IBC' THEN ISNULL(CO.ConventionOperAmount,0)
				ELSE 0
				END
				),
		-- 2010-01-13 : JFG : Modification afin de retourner le bon OperTypeIDView
		OperTypeIDView =	ISNULL(SOV.OperTypeIDView, ISNULL(tmp.OperTypeIDView, O.OperTypeID)),
		Status =
			CASE
				WHEN CCO.OperID IS NOT NULL THEN 1
				WHEN ACO.OperID IS NOT NULL THEN 2
			ELSE 0
			END,
		IQEE		= SUM	(
							CASE
								WHEN ISNULL(CO.ConventionOperTypeID,'') = 'CBQ' THEN ISNULL(CO.ConventionOperAmount,0)
							ELSE 0
							END
							),
		RendIQEE	= SUM	(
							CASE
								WHEN ISNULL(CO.ConventionOperTypeID,'') IN ('ICQ', 'MIM', 'IIQ') THEN ISNULL(CO.ConventionOperAmount,0)
							ELSE 0
							END
							),
		IQEEMaj		= SUM	(
							CASE
								WHEN ISNULL(CO.ConventionOperTypeID,'') = 'MMQ' THEN ISNULL(CO.ConventionOperAmount,0)
							ELSE 0
							END
							),
		RendIQEEMaj	= SUM	(
							CASE
								WHEN ISNULL(CO.ConventionOperTypeID,'') = 'IMQ' THEN ISNULL(CO.ConventionOperAmount,0)
							ELSE 0
							END
							),
		RendIQEETin	= SUM	(
							CASE
								WHEN ISNULL(CO.ConventionOperTypeID,'') IN ('III', 'IQI') THEN ISNULL(CO.ConventionOperAmount,0)
							ELSE 0
							END
							)
	FROM ( -- Va chercher toutes les opérations qui doivent être dans l'historique
		SELECT
			CO.OperID,
			CO.ConventionOperID,
			iCESPID = 0,
			CotisationID = 0
		FROM dbo.Un_Convention C
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
		--WHERE	CO.ConventionOperTypeID IN ('INC', 'EFB', 'BRS', 'AVC', 'INM', 'ITR', 'INS', 'IST', 'IS+', 'IBC', 'CBQ', 'ICQ', 'MIM', 'IIQ', 'MMQ', 'IMQ', 'III', 'IQI') --Modif 2010-01-19 Rémy
		WHERE	CO.ConventionOperTypeID IN (SELECT val FROM	dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_TYPE_CONV_HISTO_EAFB')))
			AND	(
						(		@Type = 'CNV'
						AND	C.ConventionID = @ID
						)
					OR	(		@Type = 'BEN'
						AND	C.BeneficiaryID = @ID
						)
					)
		-----
		UNION
		-----
		SELECT
			CE.OperID,
			ConventionOperID = 0,
			CE.iCESPID,
			CotisationID = 0
		FROM dbo.Un_Convention C
		JOIN Un_CESP CE ON CE.ConventionID = C.ConventionID
		WHERE (		@Type = 'CNV'
				AND	C.ConventionID = @ID
				)
			OR	(		@Type = 'BEN'
				AND	C.BeneficiaryID = @ID
				)
-- 2009-12-22 --> Afficher que les transaction RIN provenant de la table ConventionOper
		-----
		UNION
		-----
		SELECT
			CO.OperID,
			CO.ConventionOperID,
			iCESPID = 0,
			CotisationID = 0
		FROM dbo.Un_Convention C
			JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
			JOIN Un_Oper O ON O.OperId = CO.OperId
		--WHERE	CO.ConventionOperTypeID IN ('INC', 'EFB', 'BRS', 'AVC', 'INM', 'ITR', 'INS', 'IST', 'IS+', 'IBC', 'CBQ', 'ICQ', 'MIM', 'IIQ', 'MMQ', 'IMQ', 'III', 'IQI') --Modif 2010-01-19 Rémy
		WHERE	CO.ConventionOperTypeID IN (SELECT val FROM	dbo.fn_Mo_StringTable(dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_TYPE_CONV_HISTO_EAFB')))
			AND O.OperTypeID = 'RIN'
			AND	(	(		@Type = 'CNV'
						AND	C.ConventionID = @ID
						)
					OR	(		@Type = 'BEN'
						AND	C.BeneficiaryID = @ID
						)
					)
		) V
		JOIN Un_Oper O ON O.OperID = V.OperID
		LEFT JOIN #SpecialOperView SOV ON SOV.OperID = O.OperID
		-- Va chercher les informations des chèques
		LEFT JOIN	(
					SELECT DISTINCT L.OperID
					FROM Un_OperLinkToCHQOperation L
					JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
					JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
					) Ch ON Ch.OperID = O.OperID
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = O.OperID
		LEFT JOIN Un_ConventionOper CO ON CO.OperID = O.OperID AND V.ConventionOperID = CO.ConventionOperID
		LEFT JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		LEFT JOIN Un_Plan P ON P.PlanID = C.PlanID
		LEFT JOIN Un_CESP CE ON CE.OperID = O.OperID AND V.iCESPID = CE.iCESPID
		LEFT JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID AND Ct.CotisationID = V.CotisationID AND O.OperTypeID = 'RIN'
		LEFT JOIN Un_OperCancelation CCO ON CCO.OperSourceID = O.OperID
		LEFT JOIN Un_OperCancelation ACO ON ACO.OperID = O.OperID
		LEFT OUTER JOIN @TransactionHistoryForCS tmp
				ON tmp.OperID = O.OperID

		LEFT JOIN (select DISTINCT IdOperationFinanciere from DecaissementDepotDirect) ddd on o.OperID = ddd.IdOperationFinanciere

		LEFT JOIN (
			SELECT 
				P.OperID,
				ScholarshipPmtDtlAmount = sum(PO.PlanOperAmount)
			FROM Un_Scholarship S
			JOIN Un_ScholarshipPmt P ON P.ScholarshipID = S.ScholarshipID
			JOIN Un_PlanOper PO ON PO.OperID = P.OperID
			join Un_PlanOperType pot ON po.PlanOperTypeID = pot.PlanOperTypeID
			GROUP BY P.OperID
			)po on o.OperID = po.OperID

		--WHERE NOT (O.OperTypeID IN ('OUT', 'TIN')) AND tmp.OperID NOT IN (SELECT 1 FROM dbo.UN_CESP400 C4 
		--												WHERE C4.fCLB = 0 AND C4.fCESG = 0 AND C4.fCotisation = 0 
		--												AND C4.OperID = tmp.OperID)

	GROUP BY 
		CASE -- Christian Chénard (2011-11-16) : La liste @TypesOperCat est construite en-dehors de la requête
			WHEN ISNULL(SOV.OperTypeIDView, O.OperTypeID) NOT IN (@TypesOperCat) THEN NULL
			ELSE O.OperID
		END,
		O.OperID,
		O.OperDate,
		O.OperTypeID,
		L.iOperationID,
		Ch.OperID,
		SOV.OperTypeIDView,
		CCO.OperID,
		ACO.OperID,
		tmp.OperTypeIdView
		,ddd.IdOperationFinanciere
	ORDER BY
		O.OperDate DESC,
		O.OperID DESC	
END