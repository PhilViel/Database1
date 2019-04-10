/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntIQEE_CalculerMontantsDemande
Nom du service		: Calculer les montants d’une demande de l’IQÉÉ 
But 				: Calculer les montants d’une demande de l’IQÉÉ qui correspondent aux champs « Montant des
					  cotisations annuelles versées dans le régime », « Montant des cotisations annuelles issues d’un
					  transfert », « Montant total des cotisations annuelles » et « Montant total des cotisations
					  versées au régime » du type d’enregistrement 02.  Les montants négatifs sont utilisé pour les
					  transactions de type 06-impôt spécial et de sous-type 22-retrait prématuré de cotisations
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant unique de la convention pour laquelle le calcul est
													demandé.
						dtDate_Debut_Application	Date de début d’application des cotisations.  La date effective
													de la transaction de cotisation est utilisée pour la sélection.
						dtDate_Fin_Application		Date de fin d’application des cotisations.  La date effective de
													la transaction de cotisation est utilisée pour la sélection.
						iID_Fichier_IQEE			Identifiant du nouveau fichier de transactions en cours de
													création s'il y a lieu.												
						bFichiers_Test_Comme_		Indicateur si les fichiers test doivent être tenue en compte pour
							Production				déterminer si une transaction a déjà fait partie d'une demande à
													l'IQÉÉ.  Normalement ce n’est pas le cas.  Mais
													pour fins d’essais et de simulations il est possible de tenir
													compte des fichiers tests comme des fichiers de production.  S’il
													est absent, les fichiers test ne sont pas considérés.
						iID_Session					Identifiant de session identifiant de façon unique la création des
													fichiers de transactions
						dtDate_Creation_Fichiers	Date et heure de la création des fichiers identifiant de façon
													unique avec identifiant de session, la création des	fichiers de
													transactions.

Exemple d’appel		:	Cette procédure doit être appelée uniquement par les procédures "psIQEE_CreerTransactions02" et
						"psIQEE_CreerTransactions06_22"

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							mCotisations					Montant des cotisations annuelles
																					subventionnables versées dans la
																					convention.
						S/O							mTransfert_IN					Montant des cotisations annuelles
																					subventionnables versées dans la	
																					convention cédante qui sont transmis
																					à GUI qui est le cessionnaire.
						S/O							mTotal_Cotisations_				Somme des 2 montants précédents.
														Subventionnables
						S/O							mTotal_Cotisations				Solde des cotisations et frais au
																					31 décembre de l’année fiscale du
																					fichier en création.
						S/O							vcID_Transactions				Liste des identifiants des tran-
																					sactions de cotisation qui entre
																					dans le calcul du montant subven-
																					tionnable.
						S/O							bTransactions_Deja_				Indicateur s’il y a des transactions
														Subventionnee				de l’année fiscale qui n’entre pas
																					dans le calcul du montant subvention-
																					nable parce qu’elles ont déjà été
																					utilisé dans une autre demande de
																					l’IQÉÉ.

Historique des modifications:
		Date			Programmeur							Description												Référence
		------------	----------------------------------	-----------------------------------------				------------
		2009-03-16		Éric Deshaies						Création du service
		2009-04-22		Éric Deshaies						Ajouter le paramètre iID_Fichier_IQEE et
															traiter correctement la sélection des fichiers.
		2009-09-30		Éric Deshaies						Révision du calcul du champ "mTotal_Cotisations"
		2010-09-21		Éric Deshaies						Modification du calcul du champ "mTotal_Cotisations"
															pour tenir compte des 3 champs des transferts
															cessionnaires (IN).
		2012-06-28		Eric Michaud						Modification RIN sans ID			
		2012-12-17		Stéphane Barbeau					Constructions du curseur selon les dates officielles d'acceptation des RIN sans ID et de l'exclusion des TFRs
		2013-02-20		Stéphane Barbeau					Suppression de la construction du curseur avec RINs sans ID et TFRs exclus et amendement du curseur 
															avec RINs sans ID pour exclure les TFRs survenus entre 2012-01-01 et 2012-11-01.
		2013-02-21		Stéphane Barbeau					Ajout de l'opérateur DISTINCT dans la déclaration du Curseur curCotisations dans la condition IF @dtDate_Debut_Application >= '2012-01-01'  
		2013-02-25		Stéphane Barbeau					Restructuration de l'intéraction avec les opérations TFRs.
		2013-02-28		Stéphane Barbeau					Ajout dans @mTransfert_IN des RINs sans id datant de >= 2012-01-01:  IF @dtDate_Cotisation >= '2012-01-01' and @cCode_Type_Operation = 'RIN'
		2013-03-01		Stéphane Barbeau					Correction curseur sur RIN pas de preuve condition AND (IR.CollegeID is null OR IR.CollegeID = 0 OR  IR.CollegeID  = 4941)
															et ajout de @mFrais dans le calcul des sommes des RINs sans preuve.
		2016-02-22		Steeve Picard						Retourner le champ du montant total de RIN avec preuve à partir de 2016
          2016-06-09          Steeve Picard                           Retirement des paramètres non-utilisés @iID_Fichier_IQEE, @bFichiers_Test_Comme_Production, @iID_Session, @dtDate_Creation_Fichiers
                                                                      Ajout du paramètre @bForceRIN
***********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_CalculerMontantsDemande]
(
	@iID_Convention INT,
	@dtDate_Debut_Application DATETIME,
	@dtDate_Fin_Application DATETIME,
	@bForceRIN BIT = 0
)
RETURNS @tblIQEE_Montants TABLE
(
	mCotisations MONEY NOT NULL,
	mTransfert_IN MONEY NOT NULL,
	mTotal_Cotisations_Subventionnables MONEY NOT NULL,
	mTotal_Cotisations MONEY NOT NULL,
	vcID_Transactions VARCHAR(8000),
	bTransactions_Deja_Subventionnee BIT,
	mTotal_RIN_AvecPreuve money
)
AS
BEGIN
	-- Initialisations
	DECLARE @mCotisations MONEY,
			@mTransfert_IN MONEY,
			@mTotal_Cotisations_Subventionnables MONEY,
			@mTotal_Cotisations MONEY,
			@vcID_Transactions VARCHAR(8000),

			@iID_Cotisation INT,
			@cCode_Type_Operation CHAR(3),
			@dtDate_Cotisation DATETIME,
			@iID_Operation_Annulation INT,
			@iID_Operation INT,
			@mCotisations_Transaction MONEY,
			@mFrais MONEY,
			@mCotisation_Annee_Transfert_OUT MONEY,
			@mCotisation_Annee_Transfert_IN MONEY,
			@mCotisations_Sans_SCEE_Avant_1998 MONEY,
			@mCotisations_Sans_SCEE_APartirDe_1998 MONEY,
			@mCotisations_Avec_SCEE MONEY,
			@mTotal_RIN MONEY = 0,

			@vcIQEE_DEMANDE_COTISATION VARCHAR(200),
			@vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN VARCHAR(200),
			@vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_OUT VARCHAR(200),
			@vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_NEGATIF VARCHAR(200),
			@vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_POSITIF VARCHAR(200),

			@bCotisation_Deja_Subventionnee BIT,
			@bTransactions_Deja_Subventionnee BIT,
			@dtDate_Effective_Operation_Transfert datetime,
			@CollegeID int

	SET @mCotisations = 0
	SET @mTransfert_IN = 0
	SET @mTotal_Cotisations = 0
	SET @vcID_Transactions = ''
	SET @bTransactions_Deja_Subventionnee = 0

	-- Confirmer la valeur des paramètres absents
     IF @bForceRIN IS NULL
        SET @bForceRIN = 0
     IF @dtDate_Debut_Application >= '2012-01-01'
        SET @bForceRIN = 1

	-- Trouver les codes des catégories utilisés
	SET @vcIQEE_DEMANDE_COTISATION = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('IQEE-DEMANDE-COTISATION')
	SET @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN = [dbo].[fnOPER_ObtenirTypesOperationCategorie]
														('IQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN')
--TODO: Considérer les RIM, RIO et TRI comme des transferts lors la phase 18 de l'IQÉÉ?  Oui pour le calcul du champ "@mTransfert_IN".  Quand les données seront enregistrées dans Un_TIN.  Quoi faire avec les anciennes transactions?
	SET @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_OUT = [dbo].[fnOPER_ObtenirTypesOperationCategorie]
														('IQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_OUT')
--TODO: Considérer les RIM, RIO et TRI comme des transferts lors la phase 18 de l'IQÉÉ?  Oui pour le calcul du champ "@mCotisations" afin d'exclure les cotisations de l'année du transfert du calcul.  Quand les données seront enregistrées dans Un_OUT.  Quoi faire avec les anciennes transactions?
	SET @vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_NEGATIF = [dbo].[fnOPER_ObtenirTypesOperationCategorie]
														('IQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_NEGATIF')
	SET @vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_POSITIF = [dbo].[fnOPER_ObtenirTypesOperationCategorie]
														('IQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_POSITIF')

	DECLARE @TB_CalculerMontantsDemande TABLE (
				ID_Cotisation int,
				ID_Operation int,
				Code_Type_Operation varchar(3),
				ID_Operation_Annulation	int,
				Date_Cotisation date,
				Cotisations_Transaction money,
				Frais money,
				Cotisation_Annee_Transfert_IN money,
				Cotisations_Sans_SCEE_Avant_1998 money,
				Cotisations_Sans_SCEE_APartirDe_1998 money,
				Cotisations_Avec_SCEE money,
				Cotisation_Annee_Transfert_OUT money,
				CollegeID int
			)

	-- Rechercher toutes les transactions de cotisation applicables depuis le début jusqu'à la date de fin d'application
	-- Faire le bon select selon le temps
	IF @bForceRIN <> 0  --Inclure seulement les RIN sans Id
		BEGIN 
			INSERT INTO @TB_CalculerMontantsDemande (
					ID_Cotisation, ID_Operation, Code_Type_Operation, ID_Operation_Annulation, Date_Cotisation, Cotisations_Transaction, Frais,
					Cotisation_Annee_Transfert_IN, Cotisations_Sans_SCEE_Avant_1998, Cotisations_Sans_SCEE_APartirDe_1998, Cotisations_Avec_SCEE,
					Cotisation_Annee_Transfert_OUT, CollegeID
				)
			SELECT DISTINCT CT.CotisationID,ISNULL(OP.OperID,0),OP.OperTypeID,CA.OperID,CT.EffectDate,CT.Cotisation,CT.Fee,
					ISNULL(TI.fYearBnfCot,0),ISNULL(TI.fNoCESGCotBefore98,0),ISNULL(TI.fNoCESGCot98AndAfter,0),ISNULL(TI.fCESGCot,0),
					ISNULL(OU.fYearBnfCot,0),ISNULL(IR.CollegeID,0)
			FROM dbo.Un_Unit UN
					-- Cotisations depuis le début jusqu'à la date de fin d'application
					JOIN Un_Cotisation CT ON CT.UnitID = UN.UnitID
										AND CT.EffectDate >= @dtDate_Debut_Application
										AND CT.EffectDate <= @dtDate_Fin_Application
					JOIN Un_Oper OP ON OP.OperID = CT.OperID
					LEFT JOIN Un_OperCancelation CA ON CA.OperSourceID = OP.OperID
					LEFT JOIN Un_TIN TI ON TI.OperID = OP.OperID
					LEFT JOIN Un_OUT OU ON OU.OperID = OP.OperID
		        LEFT JOIN Un_IntReimbOper IRO ON IRO.OperID = OP.OperID
		        left JOIN Un_IntReimb IR ON IR.IntReimbID = IRO.IntReimbID --UnitID = ct.UnitID
			WHERE UN.ConventionID = @iID_Convention
					AND CT.EffectDate BETWEEN @dtDate_Debut_Application AND @dtDate_Fin_Application
				    AND ( OP.OperTypeID <> 'RIN'
						OR ( OP.OperTypeID = 'RIN' 
						    AND (IR.CollegeID is null OR IR.CollegeID = 0 OR  IR.CollegeID  = 4941
						         OR Year(CT.EffectDate) > 2015) 
						    )
					    )
		END
	ELSE
		BEGIN
			-- On utilise la déclaration du curseur d'origine
			INSERT INTO @TB_CalculerMontantsDemande (
					ID_Cotisation, ID_Operation, Code_Type_Operation, ID_Operation_Annulation, Date_Cotisation, Cotisations_Transaction, Frais,
					Cotisation_Annee_Transfert_IN, Cotisations_Sans_SCEE_Avant_1998, Cotisations_Sans_SCEE_APartirDe_1998, Cotisations_Avec_SCEE,
					Cotisation_Annee_Transfert_OUT
				)
			SELECT CT.CotisationID,ISNULL(OP.OperID,0),OP.OperTypeID,CA.OperID,CT.EffectDate,CT.Cotisation,CT.Fee,
				   ISNULL(TI.fYearBnfCot,0),ISNULL(TI.fNoCESGCotBefore98,0),ISNULL(TI.fNoCESGCot98AndAfter,0),ISNULL(TI.fCESGCot,0),
				   ISNULL(OU.fYearBnfCot,0)
			FROM dbo.Un_Unit UN
				 -- Cotisations depuis le début jusqu'à la date de fin d'application
				 JOIN Un_Cotisation CT ON CT.UnitID = UN.UnitID
									  AND CT.EffectDate <= @dtDate_Fin_Application
				 JOIN Un_Oper OP ON OP.OperID = CT.OperID
				 LEFT JOIN Un_OperCancelation CA ON CA.OperSourceID = OP.OperID
				 LEFT JOIN Un_TIN TI ON TI.OperID = OP.OperID
				 LEFT JOIN Un_OUT OU ON OU.OperID = OP.OperID
			WHERE UN.ConventionID = @iID_Convention
		END

	-- Boucler les transactions de cotisation
	SET @iID_Cotisation = 0
	WHILE EXISTS(SELECT TOP 1 * FROM @TB_CalculerMontantsDemande WHERE ID_Cotisation > @iID_Cotisation)
		BEGIN
			SELECT @iID_Cotisation = Min(ID_Cotisation) FROM @TB_CalculerMontantsDemande WHERE ID_Cotisation > @iID_Cotisation

			SELECT	@cCode_Type_Operation = Code_Type_Operation, 
					@iID_Operation_Annulation = ID_Operation_Annulation, 
					@dtDate_Cotisation = Date_Cotisation,
					@mCotisations_Transaction = Cotisations_Transaction, 
					@mFrais = Frais, 
					@mCotisation_Annee_Transfert_IN = Cotisation_Annee_Transfert_IN, 
					@mCotisations_Sans_SCEE_Avant_1998 = Cotisations_Sans_SCEE_Avant_1998,
					@mCotisations_Sans_SCEE_APartirDe_1998 = Cotisations_Sans_SCEE_APartirDe_1998, 
					@mCotisations_Avec_SCEE = Cotisations_Avec_SCEE,
					@mCotisation_Annee_Transfert_OUT = Cotisation_Annee_Transfert_OUT, 
					@iID_Operation = ID_Operation,
					@CollegeID = CollegeID
			FROM	@TB_CalculerMontantsDemande 
			WHERE	ID_Cotisation = @iID_Cotisation
										
			SET @bCotisation_Deja_Subventionnee = 0

			-- Calculer le champ "Montant des cotisations annuelles versées dans le régime"
-- TODO: Ne pas compter les cotisations en moins pour une raison d’impôt spécial 24
-- les RES et RET sont calculés dans la variable @mCotisations dans la clause ELSE
			IF NOT (@dtDate_Cotisation >= '2012-11-01' and @cCode_Type_Operation = 'TFR')
			BEGIN
				IF @dtDate_Cotisation >= @dtDate_Debut_Application AND
				   @dtDate_Cotisation <= @dtDate_Fin_Application AND
				   -- Cotisation admissible à l'IQÉÉ
				   CHARINDEX(','+@cCode_Type_Operation+',',@vcIQEE_DEMANDE_COTISATION) = 0 AND
				   -- Pas déjà subventionnée
				   @bCotisation_Deja_Subventionnee = 0 AND
				   -- N'est pas un transfert IN
				   CHARINDEX(@cCode_Type_Operation,@vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN) = 0
					BEGIN
						
						IF @cCode_Type_Operation = @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_OUT
							SET @mCotisations = @mCotisations - ISNULL(@mCotisation_Annee_Transfert_OUT,0)
						ELSE
							SET @mCotisations = @mCotisations + @mCotisations_Transaction + @mFrais
						SET @vcID_Transactions = @vcID_Transactions + CAST(@iID_Cotisation AS VARCHAR) + ','
					END
			END
			-- Calculer le champ "Montant des cotisations annuelles issues d'un transfert"
			IF @dtDate_Cotisation >= @dtDate_Debut_Application AND
			   @dtDate_Cotisation <= @dtDate_Fin_Application AND
			   -- Est un transfert IN
			   CHARINDEX(@cCode_Type_Operation,@vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN) > 0 AND
			   -- Pas déjà subventionnée
			   @bCotisation_Deja_Subventionnee = 0
				BEGIN
					--Select @dtDate_Effective_Operation_Transfert = UO.OperDate FROM Un_Oper UO WHERE OperID= @iID_Operation AND UO.OperTypeID='TFR'
					
					-- SB 2013-02-20: Une décision de GUI stipulait qu'il faut exclure les TFRs à partir du 1er novembre 2012
					--IF NOT @dtDate_Effective_Operation_Transfert < '2012-11-01'
					   --(@dtDate_Effective_Operation_Transfert >= '2012-01-01' AND @dtDate_Effective_Operation_Transfert < '2012-11-01')
					--	BEGIN
							SET @mTransfert_IN = @mTransfert_IN + ISNULL(@mCotisation_Annee_Transfert_IN,0)
							SET @vcID_Transactions = @vcID_Transactions + CAST(@iID_Cotisation AS VARCHAR) + ','
					--	END
				END

			-- Calculer le champ "Montant total des cotisations versées au régime"
-- TODO: Ne pas compter les cotisations en moins pour une raison d’impôt spécial 24
-- TODO: À réviser
			IF ((@mCotisations_Transaction + @mFrais < 0 AND
			    CHARINDEX(@cCode_Type_Operation,@vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_NEGATIF) > 0)
					OR
				(@mCotisations_Transaction + @mFrais >= 0 AND
			    CHARINDEX(','+@cCode_Type_Operation+',',@vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_POSITIF) > 0)) 
			    AND @iID_Operation_Annulation IS NULL
			   
			 --  -- SB Modification pour Correction 
				IF @dtDate_Cotisation >= '2012-11-01'
					BEGIN
						IF @cCode_Type_Operation <> 'TFR'
							BEGIN
								SET @mTotal_Cotisations = @mTotal_Cotisations + @mCotisations_Transaction + @mFrais
								SET @vcID_Transactions = @vcID_Transactions + CAST(@iID_Cotisation AS VARCHAR) + ','
							END
					END
				ELSE
					BEGIN
						SET @mTotal_Cotisations = @mTotal_Cotisations + @mCotisations_Transaction + @mFrais
						SET @vcID_Transactions = @vcID_Transactions + CAST(@iID_Cotisation AS VARCHAR) + ','
					END
			
			-- Depuis 2012/01/01 On inclus les RINs sans ID			
			IF @cCode_Type_Operation = 'RIN' and @bForceRIN <> 0
				BEGIN
				    IF IsNull(@CollegeID, 0) IN (0, 4941) 
					    SET @mTransfert_IN = @mTransfert_IN + ISNULL(@mCotisations_Transaction,0) + @mFrais
				    ELSE
				        SET @mTotal_RIN = @mTotal_RIN + ISNULL(@mCotisations_Transaction,0) + @mFrais
					SET @vcID_Transactions = @vcID_Transactions + CAST(@iID_Cotisation AS VARCHAR) + ','
				END

			IF CHARINDEX(@cCode_Type_Operation,@vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN) > 0
				SET @mTotal_Cotisations = @mTotal_Cotisations + @mCotisations_Sans_SCEE_Avant_1998 
				                                              + @mCotisations_Sans_SCEE_APartirDe_1998 
				                                              + @mCotisations_Avec_SCEE
		END

	-- Répartir les montants négatifs entre les champs "Montant des cotisations annuelles versées dans le régime" et
	-- "Montant des cotisations annuelles issues d'un transfert"
	IF @mTransfert_IN < 0
		BEGIN
			SET @mCotisations = @mCotisations + @mTransfert_IN
			SET @mTransfert_IN = 0
		END

	IF @mCotisations < 0
		BEGIN
			SET @mTransfert_IN = @mTransfert_IN + @mCotisations
			SET @mCotisations = 0
		END

	-- Calculer le total des cotisations subventionnables
	SET @mTotal_Cotisations_Subventionnables = @mCotisations + @mTransfert_IN

	-- Retourner les valeurs
	INSERT @tblIQEE_Montants (mCotisations, mTransfert_IN, mTotal_Cotisations_Subventionnables, mTotal_Cotisations,
							  vcID_Transactions, bTransactions_Deja_Subventionnee, mTotal_RIN_AvecPreuve)
	VALUES (@mCotisations, @mTransfert_IN, @mTotal_Cotisations_Subventionnables, @mTotal_Cotisations,
			@vcID_Transactions, @bTransactions_Deja_Subventionnee, @mTotal_RIN)

	RETURN
END
