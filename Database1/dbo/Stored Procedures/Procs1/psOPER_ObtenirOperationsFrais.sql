/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_ObtenirOperationsFrais
Nom du service		: Obtenir les transactions d'une opération de frais.
But 				: Obtenir les transactions d'une opération de frais ou d'annulation de frais.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						dtDate_Debut				Date de début de la période pour laquelle nous cherchons les opérations.
													Si nulle, on utilise la date du 01/01/1753.
						dtDate_Fin					Date de fin de la période pour laquelle nous cherchons les opérations.
													Si nulle, on utilise la date du jour.

Exemple d’appel		:	DECLARE @return_value int, @vcCode_Message varchar(10)
						EXEC @return_value = [dbo].[psOPER_ObtenirOperationsFrais]
						  @dtDate_Debut = '20110919',
						  @dtDate_Fin = '20110925',
						  @vcCode_Message = @vcCode_Message OUTPUT

Paramètres de sortie:	Table							Champ							Description
		  				-------------------------		--------------------------- 	---------------------------------
		  				Un_Plan							iOrdre_Plan						Ordre d'affichage
		  				tblCONV_RegroupementsRegimes	vcDescription_Regroupement		Description du regroupement de régime
		  												_Regime			
		  																				de régime
						Un_Oper							dtDate_Operation				Date de l'opération (OperDate)
						Un_Convention					vcNo_Convention					Numéro de la convension (ConventionNo)
						Un_Human						vcSouscripteur					Nom, Prénom du scouscripteur
						tblOPER_TypesFrais				vcCode_Type_Frais				Code du type de frais
						tblOPER_Frais					mMontant_Frais					Montant H.T. du frais
						tblOPER_FraisTaxes				mMontant_TPS					Montant de la TPS
						tblOPER_FraisTaxes				mMontant_TVQ					Montant de la TVQ
						S/O								mMontant_Total					Montant total
						S/O								vcCode_Message					Message de retour en cas de retour à 0
						S/O								iCode_Retour					1 = Succès
																						0 = Erreur de paramètres
																						-1 = Erreur non gérée

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-03-02		Corentin Menthonnex					Création du service		
		2011-09-28		Donald Huppé						GLPI 6134 : Ajout d'un tri par date d'opération					

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirOperationsFrais]
    (
      @dtDate_Debut DATETIME ,
      @dtDate_Fin DATETIME , 
      @vcCode_Message VARCHAR(10) OUTPUT
    )
AS 
    BEGIN

        BEGIN TRY
			---------------------------------------------------------------------------------------------
			-- Initialisation de la procédure
			---------------------------------------------------------------------------------------------
			-- On set les dates si une des deux n'est pas remplie
			SET @dtDate_Debut = ISNULL(@dtDate_Debut,'17530101');
			SET @dtDate_Fin = ISNULL(@dtDate_Fin,GETDATE());
				
			IF @dtDate_Fin < @dtDate_Debut
				BEGIN
					SET @vcCode_Message = 'OPERE0023' ;
					RETURN 0 ;
				END
				
			--Récupération des groupes de régimes	
			DECLARE @tblTEMP_Regroupements TABLE (
				iID_Regroupement_Regime INT ,
				vcDescription varchar(50)
			)
			INSERT INTO @tblTEMP_Regroupements EXEC dbo.psCONV_ObtenirRegroupementsRegimesPourParametreDeRapport @cID_Langue = 'FRA'
				
			---------------------------------------------------------------------------------------------
			-- Sélection des sortants
			---------------------------------------------------------------------------------------------
            SELECT  p.OrderOfPlanInReport AS iOrdre_Plan ,
					r.vcDescription AS vcDescription_Regroupement_Regime ,
                    o.OperDate AS dtDate_Operation ,
                    cv.ConventionNo AS vcNo_Convention ,
                    dbo.fn_Mo_HumanName(cv.SubscriberID) AS vcSouscripteur ,
                    tf.vcCode_Type_Frais AS vcCode_Type_Frais ,
                    f.mMontant_Frais AS mMontant_Frais ,
                    dbo.fnOPER_ObtenirMontantTaxeFrais(f.iID_Frais, 'OPER_TAXE_TPS') AS mMontant_TPS ,
                    dbo.fnOPER_ObtenirMontantTaxeFrais(f.iID_Frais, 'OPER_TAXE_TVQ') AS mMontant_TVQ ,
                    f.mMontant_Frais + dbo.fnOPER_ObtenirMontantTaxeFrais(f.iID_Frais, 'OPER_TAXE_TPS') + dbo.fnOPER_ObtenirMontantTaxeFrais(f.iID_Frais, 'OPER_TAXE_TVQ') AS mMontant_Total
            FROM    dbo.tblOPER_Frais f
                    INNER JOIN dbo.tblOPER_TypesFrais tf ON tf.iID_Type_Frais = f.iID_Type_Frais
                    INNER JOIN dbo.Un_Oper o ON o.OperID = f.iID_Oper
                    INNER JOIN dbo.Un_Cotisation co ON co.OperID = o.OperID
                    INNER JOIN dbo.Un_Unit u ON u.UnitID = co.UnitID
                    INNER JOIN dbo.Un_Convention cv ON cv.ConventionID = u.ConventionID
                    INNER JOIN dbo.Un_Plan p ON p.PlanID = cv.PlanID
                    INNER JOIN @tblTEMP_Regroupements r ON r.iID_Regroupement_Regime = p.iID_Regroupement_Regime
            WHERE   o.OperDate BETWEEN @dtDate_Debut AND @dtDate_Fin
            ORDER BY 
					p.iID_Regroupement_Regime,
					cv.ConventionNo,
					o.OperDate

        END TRY
        
        BEGIN CATCH
			-- Lever l'erreur et faire le rollback
            DECLARE @ErrorMessage NVARCHAR(4000) ,
                @ErrorSeverity INT ,
                @ErrorState INT

            SET @ErrorMessage = ERROR_MESSAGE()
            SET @ErrorSeverity = ERROR_SEVERITY()
            SET @ErrorState = ERROR_STATE()

            RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG ;

			-- Retourner -1 en cas d'erreur non gérée de traitement
            RETURN -1
        END CATCH

		-- Retourner 1 en cas de réussite du traitement
        RETURN 1
    END

