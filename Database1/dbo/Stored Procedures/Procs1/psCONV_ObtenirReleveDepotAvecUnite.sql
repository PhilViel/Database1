/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Code de service		:		psCONV_ObtenirReleveDepotAvecUnite
Nom du service		:		
But					:		Obtenir les données du relevé de dépôt avec le détail par unité pour les calculs prévisionnels
Facette				:		
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
                        @iIDConvention				Numéro de convention						Oui
Exemples d'appel:
				EXEC dbo.psCONV_ObtenirReleveDepotAvecUnite 257755, '2009-01-01', '2009-12-31'

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-François Gauthier					Création de la procédure
						2010-05-10					Jean-François Gauthier					Ajout de la gestion des erreurs
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirReleveDepotAvecUnite]
	(
		@iIDConvention	INT
		,@dtDateDebut	DATETIME
		,@dtDateFin		DATETIME
	)
AS
	BEGIN
        SELECT 1/0
        /*
		SET NOCOUNT ON
		BEGIN TRY
			SELECT  
				iIDConvention			
				,iIDSouscripteur		
				,iIDBeneficiaire		
				,vcNumeroConvention		
				,iQuantiteUnite			
				,vcTypeOperation		
				,mFraisCotisation		
				,mFrais					
				,mSCEE 					
				,mIntSCEE				
				,mSCEESup 				
				,mIntSCEESup		
				,mIQEE 				
				,mIntIQEE 				
				,mBec 					
				,mIntBEC				
				,mPAE 					
				,mIntPAE 				
				,mAutreRev 				
				,mIntAutreRev			
				,iAnneeQualif 			
				,mBourse 				
				,mMntSouscrit 				
				,mMntTheoMens			
				,dtEntreeVigueur		
				,dtRembEstime 			
				,dtFinCotisation 		
				,dtFinRegime			
				,vcPrenomRep 			
				,vcNomRep 				
				,vcTelRep 				
				,vcPrenomDir			
				,vcNomDir 				
				,vcTelDir 				
				,mCoutEtude 			
				,vcPrenomSouscripteur	
				,vcNomSouscripteur		
				,vcAdresseSouscripteur	
				,vcVilleSouscripteur	
				,vcProvinceSouscripteur 
				,vcPaysSouscripteur		
				,vcCodePostSouscripteur 
				,bPrincipalResponsableErreur 
				,bPrincipalResponsableManquant 
				,vcLangue 				
				,vcPrenomBenef 			
				,vcNomBenef 			
				,vcNASBenef				
				,vcCompagnie			
				,vcRegime				
				,cTypeDonnee			
				,vcTexteDiplome 		
				,vcIDRegime 			
				,vcDerniereAnnee 		
				,vcAvantDernAnnee		
				,vcCourrielSouscripteur 
				,vcTypeContact 			
				,cSexeSouscripteur		
				,iPayementParAnnee		
				,iNombrePayement 		
				,dtDateCalcul			
				,dtDateFin					
				,mIQEEMaj				
				,iIDUnite				
				,nDiffAnneeIQEE			
				,nDiffAnneeSCEE			
				,bEntreeVigueurIQEE		
				,bEntreeVigueurSCEE		
			FROM 
				dbo.fntCONV_ObtenirReleveDepotAvecUnite(@iIDConvention, @dtDateDebut, @dtDateFin)
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
        */
	END