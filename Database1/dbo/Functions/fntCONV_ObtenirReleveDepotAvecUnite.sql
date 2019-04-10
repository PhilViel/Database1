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
Code de service		:		fntCONV_ObtenirReleveDepotAvecUnite
Nom du service		:		
But					:		Obtenir les données du relevé de dépôt avec le détail par unité pour les calculs prévisionnels
Facette				:		
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
                        @iIDConvention				Numéro de convention						Oui
Exemples d'appel:
				SELECT * FROM dbo.fntCONV_ObtenirReleveDepotAvecUnite(270974, '2009-01-01', '2009-12-31')
				SELECT * FROM dbo.fntCONV_ObtenirReleveDepotAvecUnite(334310, '2009-01-01', '2009-12-31')
				SELECT * FROM dbo.fntCONV_ObtenirReleveDepotAvecUnite(313383, '2009-01-01', '2009-12-31')
				SELECT MAX(mBEC) FROM dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite rel WHERE	rel.iIDConvention = 306088 AND ISNULL(vcTypeOperation,'') = 'PRJ'

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-02					Jean-François Gauthier					Création de la fonction
						2009-10-06					Jean-François Gauthier					Ajout du SELECT sommarisé
						2009-10-09					Jean-François Gauthier					Ajout des paramètres de date de début et de fin
						2009-10-16					Jean-François Gauthier					Modification afin de placer les montants d'intérêts SCEE
																							sur le dernier groupe d'unité		
						2009-10-20					Jean-François Gauthier					Modification du type de iQuantiteUnite
																							Ajout des ISNULL sur tous les montants
						2009-10-23					Jean-François Gauthier					Ajout des 4 champs :dDiffMoisIQEE
																												dDiffMoisSCEE
																												bEntreeVigueurIQEE
																												bEntreeVigueurSCEE
						2009-10-29					Jean-François Gauthier					Correction attribution des intérêts SCEE
						2010-05-27					Jean-François Gauthier					Retour des lignes PRJ pour les opérations les plus récentes
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirReleveDepotAvecUnite]
	(
		@iIDConvention	INT
		,@dtDateDebut	DATETIME
		,@dtDateFin		DATETIME
	)
RETURNS @tRelDepUnit TABLE
			(
			iIDConvention			INT	
			,iIDSouscripteur		INT
			,iIDBeneficiaire		INT	
			,vcNumeroConvention		VARCHAR(20)
			,iQuantiteUnite			FLOAT
			,vcTypeOperation		VARCHAR(3)
			,mFraisCotisation		MONEY
			,mFrais					MONEY
			,mSCEE 					MONEY
			,mIntSCEE				MONEY
			,mSCEESup 				MONEY
			,mIntSCEESup			MONEY
			,mIQEE 					MONEY
			,mIntIQEE 				MONEY
			,mBec 					MONEY
			,mIntBEC				MONEY
			,mPAE 					MONEY
			,mIntPAE 				MONEY
			,mAutreRev 				MONEY
			,mIntAutreRev			MONEY
			,iAnneeQualif 			INT
			,mBourse 				MONEY
			,mMntSouscrit 			MONEY	
			,mMntTheoMens			MONEY
			,dtEntreeVigueur		DATETIME
			,dtRembEstime 			DATETIME
			,dtFinCotisation 		DATETIME
			,dtFinRegime			DATETIME
			,vcPrenomRep 			VARCHAR(100)
			,vcNomRep 				VARCHAR(100)
			,vcTelRep 				VARCHAR(20)	
			,vcPrenomDir			VARCHAR(100)
			,vcNomDir 				VARCHAR(100)
			,vcTelDir 				VARCHAR(20)
			,mCoutEtude 			MONEY	
			,vcPrenomSouscripteur	VARCHAR(100)
			,vcNomSouscripteur		VARCHAR(100)
			,vcAdresseSouscripteur	VARCHAR(200)
			,vcVilleSouscripteur	VARCHAR(100)	
			,vcProvinceSouscripteur VARCHAR(100)
			,vcPaysSouscripteur		VARCHAR(100)
			,vcCodePostSouscripteur VARCHAR(50)
			,bPrincipalResponsableErreur BIT
			,bPrincipalResponsableManquant BIT
			,vcLangue 				VARCHAR(50)
			,vcPrenomBenef 			VARCHAR(100)
			,vcNomBenef 			VARCHAR(100)
			,vcNASBenef				VARCHAR(75)
			,vcCompagnie			VARCHAR(200)
			,vcRegime				VARCHAR(50)	
			,cTypeDonnee			CHAR(1)
			,vcTexteDiplome 		VARCHAR(150)
			,vcIDRegime 			VARCHAR(3)
			,vcDerniereAnnee 		VARCHAR(4)	
			,vcAvantDernAnnee		VARCHAR(50)
			,vcCourrielSouscripteur VARCHAR(100)
			,vcTypeContact 			VARCHAR(3)
			,cSexeSouscripteur		CHAR(1)			
			,iPayementParAnnee		INT
			,iNombrePayement 		INT
			,dtDateCalcul			DATETIME
			,dtDateFin				DATETIME	
			,mIQEEMaj				MONEY
			,iIDUnite				INT
			,nDiffAnneeIQEE			NUMERIC(18,10)
			,nDiffAnneeSCEE			NUMERIC(18,10)
			,bEntreeVigueurIQEE		BIT
			,bEntreeVigueurSCEE		BIT
			)
AS
	BEGIN

        INSERT INTO @tRelDepUnit
                (iIDConvention ,
                 iIDSouscripteur ,
                 iIDBeneficiaire ,
                 vcNumeroConvention ,
                 iQuantiteUnite ,
                 vcTypeOperation ,
                 mFraisCotisation ,
                 mFrais ,
                 mSCEE ,
                 mIntSCEE ,
                 mSCEESup ,
                 mIntSCEESup ,
                 mIQEE ,
                 mIntIQEE ,
                 mBec ,
                 mIntBEC ,
                 mPAE ,
                 mIntPAE ,
                 mAutreRev ,
                 mIntAutreRev ,
                 iAnneeQualif ,
                 mBourse ,
                 mMntSouscrit ,
                 mMntTheoMens ,
                 dtEntreeVigueur ,
                 dtRembEstime ,
                 dtFinCotisation ,
                 dtFinRegime ,
                 vcPrenomRep ,
                 vcNomRep ,
                 vcTelRep ,
                 vcPrenomDir ,
                 vcNomDir ,
                 vcTelDir ,
                 mCoutEtude ,
                 vcPrenomSouscripteur ,
                 vcNomSouscripteur ,
                 vcAdresseSouscripteur ,
                 vcVilleSouscripteur ,
                 vcProvinceSouscripteur ,
                 vcPaysSouscripteur ,
                 vcCodePostSouscripteur ,
                 bPrincipalResponsableErreur ,
                 bPrincipalResponsableManquant ,
                 vcLangue ,
                 vcPrenomBenef ,
                 vcNomBenef ,
                 vcNASBenef ,
                 vcCompagnie ,
                 vcRegime ,
                 cTypeDonnee ,
                 vcTexteDiplome ,
                 vcIDRegime ,
                 vcDerniereAnnee ,
                 vcAvantDernAnnee ,
                 vcCourrielSouscripteur ,
                 vcTypeContact ,
                 cSexeSouscripteur ,
                 iPayementParAnnee ,
                 iNombrePayement ,
                 dtDateCalcul ,
                 dtDateFin ,
                 mIQEEMaj ,
                 iIDUnite ,
                 nDiffAnneeIQEE ,
                 nDiffAnneeSCEE ,
                 bEntreeVigueurIQEE ,
                 bEntreeVigueurSCEE
                )
        VALUES
                (0 , -- iIDConvention - int
                 0 , -- iIDSouscripteur - int
                 0 , -- iIDBeneficiaire - int
                 '' , -- vcNumeroConvention - varchar(20)
                 0.0 , -- iQuantiteUnite - float
                 '' , -- vcTypeOperation - varchar(3)
                 NULL , -- mFraisCotisation - money
                 NULL , -- mFrais - money
                 NULL , -- mSCEE - money
                 NULL , -- mIntSCEE - money
                 NULL , -- mSCEESup - money
                 NULL , -- mIntSCEESup - money
                 NULL , -- mIQEE - money
                 NULL , -- mIntIQEE - money
                 NULL , -- mBec - money
                 NULL , -- mIntBEC - money
                 NULL , -- mPAE - money
                 NULL , -- mIntPAE - money
                 NULL , -- mAutreRev - money
                 NULL , -- mIntAutreRev - money
                 0 , -- iAnneeQualif - int
                 NULL , -- mBourse - money
                 NULL , -- mMntSouscrit - money
                 NULL , -- mMntTheoMens - money
                 GETDATE() , -- dtEntreeVigueur - datetime
                 GETDATE() , -- dtRembEstime - datetime
                 GETDATE() , -- dtFinCotisation - datetime
                 GETDATE() , -- dtFinRegime - datetime
                 '' , -- vcPrenomRep - varchar(100)
                 '' , -- vcNomRep - varchar(100)
                 '' , -- vcTelRep - varchar(20)
                 '' , -- vcPrenomDir - varchar(100)
                 '' , -- vcNomDir - varchar(100)
                 '' , -- vcTelDir - varchar(20)
                 NULL , -- mCoutEtude - money
                 '' , -- vcPrenomSouscripteur - varchar(100)
                 '' , -- vcNomSouscripteur - varchar(100)
                 '' , -- vcAdresseSouscripteur - varchar(200)
                 '' , -- vcVilleSouscripteur - varchar(100)
                 '' , -- vcProvinceSouscripteur - varchar(100)
                 '' , -- vcPaysSouscripteur - varchar(100)
                 '' , -- vcCodePostSouscripteur - varchar(50)
                 NULL , -- bPrincipalResponsableErreur - bit
                 NULL , -- bPrincipalResponsableManquant - bit
                 '' , -- vcLangue - varchar(50)
                 '' , -- vcPrenomBenef - varchar(100)
                 '' , -- vcNomBenef - varchar(100)
                 '' , -- vcNASBenef - varchar(75)
                 '' , -- vcCompagnie - varchar(200)
                 '' , -- vcRegime - varchar(50)
                 '' , -- cTypeDonnee - char(1)
                 '' , -- vcTexteDiplome - varchar(150)
                 '' , -- vcIDRegime - varchar(3)
                 '' , -- vcDerniereAnnee - varchar(4)
                 '' , -- vcAvantDernAnnee - varchar(50)
                 '' , -- vcCourrielSouscripteur - varchar(100)
                 '' , -- vcTypeContact - varchar(3)
                 '' , -- cSexeSouscripteur - char(1)
                 0 , -- iPayementParAnnee - int
                 0 , -- iNombrePayement - int
                 GETDATE() , -- dtDateCalcul - datetime
                 GETDATE() , -- dtDateFin - datetime
                 NULL , -- mIQEEMaj - money
                 0 , -- iIDUnite - int
                 NULL , -- nDiffAnneeIQEE - numeric(18, 10)
                 NULL , -- nDiffAnneeSCEE - numeric(18, 10)
                 NULL , -- bEntreeVigueurIQEE - bit
                 NULL  -- bEntreeVigueurSCEE - bit
                )
                
        RETURN
        /*
		-- RECHERCHE DU GROUPE UNITÉ LE PLUS RÉCENT
		DECLARE 
			@iIDUnitePlusAncienne	INT
			,@mTotalBEC				MONEY
			
		DECLARE @tUnit TABLE
						(
						iIDConvention			INT	
						,iIDSouscripteur		INT
						,iIDBeneficiaire		INT	
						,vcNumeroConvention		VARCHAR(20)
						,iQuantiteUnite			FLOAT
						,vcTypeOperation		VARCHAR(3)
						,mFraisCotisation		MONEY
						,mFrais					MONEY
						,mSCEE 					MONEY
						,mIntSCEE				MONEY
						,mSCEESup 				MONEY
						,mIntSCEESup			MONEY
						,mIQEE 					MONEY
						,mIntIQEE 				MONEY
						,mBec 					MONEY
						,mIntBEC				MONEY
						,mPAE 					MONEY
						,mIntPAE 				MONEY
						,mAutreRev 				MONEY
						,mIntAutreRev			MONEY
						,iAnneeQualif 			INT
						,mBourse 				MONEY
						,mMntSouscrit 			MONEY	
						,mMntTheoMens			MONEY
						,dtEntreeVigueur		DATETIME
						,dtRembEstime 			DATETIME
						,dtFinCotisation 		DATETIME
						,dtFinRegime			DATETIME
						,vcPrenomRep 			VARCHAR(100)
						,vcNomRep 				VARCHAR(100)
						,vcTelRep 				VARCHAR(20)	
						,vcPrenomDir			VARCHAR(100)
						,vcNomDir 				VARCHAR(100)
						,vcTelDir 				VARCHAR(20)
						,mCoutEtude 			MONEY	
						,vcPrenomSouscripteur	VARCHAR(100)
						,vcNomSouscripteur		VARCHAR(100)
						,vcAdresseSouscripteur	VARCHAR(200)
						,vcVilleSouscripteur	VARCHAR(100)	
						,vcProvinceSouscripteur VARCHAR(100)
						,vcPaysSouscripteur		VARCHAR(100)
						,vcCodePostSouscripteur VARCHAR(50)
						,bPrincipalResponsableErreur BIT
						,bPrincipalResponsableManquant BIT
						,vcLangue 				VARCHAR(50)
						,vcPrenomBenef 			VARCHAR(100)
						,vcNomBenef 			VARCHAR(100)
						,vcNASBenef				VARCHAR(75)
						,vcCompagnie			VARCHAR(200)
						,vcRegime				VARCHAR(50)	
						,cTypeDonnee			CHAR(1)
						,vcTexteDiplome 		VARCHAR(150)
						,vcIDRegime 			VARCHAR(3)
						,vcDerniereAnnee 		VARCHAR(4)	
						,vcAvantDernAnnee		VARCHAR(50)
						,vcCourrielSouscripteur VARCHAR(100)
						,vcTypeContact 			VARCHAR(3)
						,cSexeSouscripteur		CHAR(1)			
						,iPayementParAnnee		INT
						,iNombrePayement 		INT
						,dtDateCalcul			DATETIME
						,dtDateFin				DATETIME	
						,mIQEEMaj				MONEY
						,iIDUnite				INT
						,nDiffAnneeIQEE			NUMERIC(18,10)
						,nDiffAnneeSCEE			NUMERIC(18,10)
						,bEntreeVigueurIQEE		BIT
						,bEntreeVigueurSCEE		BIT
						)

		SET @iIDUnitePlusAncienne = (SELECT TOP 1 u.UnitID FROM dbo.Un_Unit u WHERE u.ConventionID =  @iIDConvention ORDER BY u.InForceDate ASC, u.UnitID ASC)			
		SET @mTotalBEC = (SELECT MAX(mBEC) FROM dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite rel WHERE	rel.iIDConvention = @iIDConvention AND ISNULL(vcTypeOperation,'') = 'PRJ')

		INSERT INTO @tUnit
		(
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
		)
		SELECT
			rel.iIDConvention			
			,rel.iIDSouscripteur
			,rel.iIDBeneficiaire			
			,rel.vcNumeroConvention
			,mQuantiteUnite			= ISNULL(rel.mQuantiteUnite, 0)
			,rel.vcTypeOperation		
			,mFraisCotisation		= ISNULL((SELECT SUM(r.mFraisCotisation) FROM dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite r WHERE r.iIDConvention = rel.iIDConvention AND r.iNbGroupeUnite = rel.iNbGroupeUnite AND r.dtDateOperation	BETWEEN @dtDateDebut AND @dtDateFin),0)
			,mFrais					= ISNULL((SELECT SUM(r.mFrais) FROM dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite r WHERE r.iIDConvention = rel.iIDConvention AND r.iNbGroupeUnite = rel.iNbGroupeUnite AND r.dtDateOperation	BETWEEN @dtDateDebut AND @dtDateFin),0) 
			,mSCEE = ISNULL(rel.mSCEE, 0) 					
			,mIntSCEE = CASE 
							WHEN rel.iNbGroupeUnite = @iIDUnitePlusAncienne THEN ISNULL(rel.mIntSCEE, 0)
							ELSE 0
						END				
			,rel.mSCEESup 					
			,mIntSCEESup = CASE 
								WHEN rel.iNbGroupeUnite = @iIDUnitePlusAncienne THEN ISNULL(rel.mIntSCEESup, 0) 
								ELSE 0
							END				
			,mIQEE = ISNULL(rel.mIQEE, 0)
			,mIntIQEE = ISNULL(rel.mIntIQEE, 0) 				
			,mBec = ISNULL(rel.mBec, 0) 						
			,mIntBEC = CASE WHEN @mTotalBEC <> 0 THEN ISNULL(rel.mIntBEC * (rel.mBec / @mTotalBEC), 0) 
							ELSE rel.mIntBEC
						END
			,mPAE = ISNULL(rel.mPAE, 0) 					
			,mIntPAE = ISNULL(rel.mIntPAE, 0) 				
			,mAutreRev = ISNULL(rel.mAutreRev, 0) 					
			,mIntAutreRev = ISNULL(rel.mIntAutreRev, 0)
			,rel.vcAnneeQualif 			
			,mBourse = ISNULL(rel.mBourse, 0) 				
			,mMntSouscrit = ISNULL(rel.mMntSouscrit, 0) 				
			,mMntTheoMens			= ISNULL(MAX(rel.mMntTheoMens),0)
			,rel.dtEntreeVigueur		
			,rel.dtRembEstime 			
			,rel.dtFinCotisation 			
			,rel.dtFinRegime 
			,rel.vcPrenomRep 			
			,rel.vcNomRep 				
			,rel.vcTelRep 					
			,rel.vcPrenomDir 
			,rel.vcNomDir 				
			,rel.vcTelDir 				
			,mCoutEtude = ISNULL(rel.mCoutEtude, 0) 				
			,rel.vcPrenomSouscripteur 
			,rel.vcNomSouscripteur		
			,rel.vcAdresseSouscripteur 
			,rel.vcVilleSouscripteur		
			,rel.vcProvinceSouscripteur 
			,rel.vcPaysSouscripteur		
			,rel.vcCodePostSouscripteur 
			,rel.bPrincipalResponsableErreur 
			,rel.bPrincipalResponsableManquant 
			,rel.vcLangue 				
			,rel.vcPrenomBenef 			
			,rel.vcNomBenef 				
			,rel.vcNASBenef 
			,rel.vcCompagnie			
			,rel.vcRegime					
			,rel.vcTypeDonnee 
			,rel.vcTexteDiplome 		
			,rel.iIDRegime 				
			,rel.vcDerniereAnnee 			
			,rel.vcAvantDernAnnee 
			,rel.vcCourrielSouscripteur 
			,rel.vcTypeContact 			
			,rel.cSexeSouscripteur 			
			,rel.iPayementParAnnee 
			,rel.iNombrePayement 		
			,rel.dtDateCalcul			
			,rel.dtDateFin					
			,mIQEEMaj = ISNULL(rel.mIQEEMaj, 0)
			,iIDUnite				= ISNULL(rel.iNbGroupeUnite, 0)
			,rel.nDiffAnneeIQEE
			,rel.nDiffAnneeSCEE
			,rel.bEntreeVigueurIQEE
			,rel.bEntreeVigueurSCEE
		FROM 
			dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite rel
			INNER JOIN 
			(
			SELECT
				MaxDateOperation = MAX(dtDateOperation),
				iNbGroupeUnite,
				iIDConvention
			FROM 
				dbo.tblCONV_DonneeReleveDepotAvecDetailParUnite rel
			WHERE
				iIDConvention = @iIDConvention
				AND
				vcTypeOperation = 'PRJ'
			GROUP BY
				iNbGroupeUnite
				,iIDConvention
			) tmp
				ON	rel.iNbGroupeUnite		= tmp.iNbGroupeUnite 
					AND rel.dtDateOperation = tmp.MaxDateOperation
					AND rel.iIDConvention	= tmp.iIDConvention
		WHERE
			rel.iIDConvention = @iIDConvention
			AND
			vcTypeOperation IS NOT NULL
		GROUP BY
			rel.iNbGroupeUnite
			,rel.iIDConvention			
			,rel.iIDSouscripteur
			,rel.iIDBeneficiaire			
			,rel.vcNumeroConvention
			,rel.mQuantiteUnite
			,rel.vcTypeOperation		
			,rel.mSCEE 					
			,rel.mIntSCEE				
			,rel.mSCEESup 					
			,rel.mIntSCEESup 
			,rel.mIQEE 					
			,rel.mIntIQEE 				
			,rel.mBec 						
			,rel.mIntBEC 
			,rel.mPAE 					
			,rel.mIntPAE 				
			,rel.mAutreRev 					
			,rel.mIntAutreRev 
			,rel.vcAnneeQualif 			
			,rel.mBourse 				
			,rel.mMntSouscrit 				
			,rel.dtEntreeVigueur		
			,rel.dtRembEstime 			
			,rel.dtFinCotisation 			
			,rel.dtFinRegime 
			,rel.vcPrenomRep 			
			,rel.vcNomRep 				
			,rel.vcTelRep 					
			,rel.vcPrenomDir 
			,rel.vcNomDir 				
			,rel.vcTelDir 				
			,rel.mCoutEtude 				
			,rel.vcPrenomSouscripteur 
			,rel.vcNomSouscripteur		
			,rel.vcAdresseSouscripteur 
			,rel.vcVilleSouscripteur		
			,rel.vcProvinceSouscripteur 
			,rel.vcPaysSouscripteur		
			,rel.vcCodePostSouscripteur 
			,rel.bPrincipalResponsableErreur 
			,rel.bPrincipalResponsableManquant 
			,rel.vcLangue 				
			,rel.vcPrenomBenef 			
			,rel.vcNomBenef 				
			,rel.vcNASBenef 			
			,rel.vcCompagnie			
			,rel.vcRegime					
			,rel.vcTypeDonnee 
			,rel.vcTexteDiplome 		
			,rel.iIDRegime 				
			,rel.vcDerniereAnnee 			
			,rel.vcAvantDernAnnee 
			,rel.vcCourrielSouscripteur 
			,rel.vcTypeContact 			
			,rel.cSexeSouscripteur 			
			,rel.iPayementParAnnee 
			,rel.iNombrePayement 		
			,rel.dtDateCalcul			
			,rel.dtDateFin					
			,rel.mIQEEMaj
			,rel.nDiffAnneeIQEE
			,rel.nDiffAnneeSCEE
			,rel.bEntreeVigueurIQEE
			,rel.bEntreeVigueurSCEE
		ORDER BY
			rel.iNbGroupeUnite
			
			
		INSERT INTO @tRelDepUnit
		(
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
		)
		SELECT 
			iIDConvention			
			,iIDSouscripteur		
			,iIDBeneficiaire		
			,vcNumeroConvention		
			,iQuantiteUnite			
			,vcTypeOperation		
			,mFraisCotisation		
			,mFrais					
			,SUM(mSCEE) 					
			,SUM(mIntSCEE)				
			,SUM(mSCEESup) 				
			,SUM(mIntSCEESup)			
			,mIQEE 					
			,mIntIQEE 				
			,SUM(mBec)					
			,SUM(mIntBEC)				
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
			@tUnit
		GROUP BY
			iIDConvention			
			,iIDSouscripteur		
			,iIDBeneficiaire		
			,vcNumeroConvention		
			,iQuantiteUnite			
			,vcTypeOperation		
			,mFraisCotisation		
			,mFrais					
			,mIQEE 					
			,mIntIQEE 								
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
			--,vcCompagnie			
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
		
		RETURN
    */
END