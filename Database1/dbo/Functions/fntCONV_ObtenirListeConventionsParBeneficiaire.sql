/***********************************************************************************************************************
Code de service :	fntCONV_ObtenirListeConventionsParBeneficiaire
Nom du service	:	1.1.8 Obtenir les conventions pour un bénéficiaire
But				:	Récupérer les conventions pour un bénéficiaire
Description		:	Cette fonction est utilisée pour sélectionner la liste des conventions pour un bénéficiaire
						selon l'identifiant unique du bénéficiaire passé en paramètre
Facette			:	CONV
Reférence		:	P171U - Service du noyau de la facette CONV - Conventions, section 1.1.8
 
Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------
						dtDateReleve				Date du relevé								Oui
						iIDBeneficiaire				Identifiant unique du bénéficiaire			Oui
 
Exemples d'appel:
		SELECT * FROM dbo.fntCONV_ObtenirListeConventionsParBeneficiaire('2009-10-15', 441074)
 
Parametres de sortie :
 
        Table				Champs						Description
		----------------    ------------------------    -----------------------------------------------------------------------
		Un_Convention		ConventionID				Identiiant unique de la convention (prendra la valeur -1 si une errer se produit)
							SubscriberID				Identifiant unique du souscripteur
							BeneficiaryID				Identifiant	unique du bénéficiaire
							ConventionNO				Numéro de la convention
		Un_Plan				PlanTypeID					Identifiant unique du plan
							PlanDesc					Description du plan de la convention							
 
Historique des modifications :
 
		Date			Programmeur						Description
		----------		----------------------------	---------------------------------------------------------------------------
		2009-10-15		Jean-François Gauthier			Création de la fonction
		2009-10-19		Jean-François Gauthier			Ajout du DISTINCT, car il peut y avoir des doublons si plusieurs groupes d'unité dans une convention
		2010-09-21		Pierre Paquet					Correction: ne pas valider le statut REE.
        2015-12-01      Steeve Picard                   Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
***********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirListeConventionsParBeneficiaire]
(
	@dtDateReleve		DATETIME,
	@iIDBeneficiaire	INT		
)
RETURNS @tConvention TABLE (
		iConventionID		INT,
		iSubscriberID		INT,
		iBeneficiaryID		INT,
		vcConventionNO		VARCHAR(15),
		cPlanTypeID		    CHAR(3),
		vcPlanDesc			VARCHAR(75)
	)
AS
BEGIN
	DECLARE @iIDConvention INT	
 
	-- 1. VALIDATION DE LA PRÉSENCE DES PARAMÈTRES OBLIGATOIRES
	IF (@dtDateReleve IS NULL OR @iIDBeneficiaire IS NULL)
		BEGIN
			INSERT INTO @tConvention (
			        iConventionID	
			        ,iSubscriberID	
			        ,iBeneficiaryID	
			        ,vcConventionNO	
			        ,cPlanTypeID	
			        ,vcPlanDesc		
			    )
			VALUES (
			        -1,
			        NULL,
			        NULL,
			        NULL,
			        NULL,
			        NULL
			    )
		END
	ELSE
		BEGIN
			INSERT INTO @tConvention (
			        iConventionID	
			        ,iSubscriberID	
			        ,iBeneficiaryID	
			        ,vcConventionNO	
			        ,cPlanTypeID	
			        ,vcPlanDesc		
			    )
			SELECT  DISTINCT
					c.ConventionID
					,c.SubscriberID
					,c.BeneficiaryID
					,c.ConventionNO
					,p.PlanTypeID
					,p.PlanDesc					
			FROM    dbo.Un_Convention c
                    --INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtDateReleve, NULL) s ON s.conventionID = c.ConventionID
				    INNER JOIN dbo.Un_Unit u ON u.ConventionID = c.ConventionID
				    INNER JOIN dbo.Un_Plan p ON p.PlanID = c.PlanID
			WHERE   c.BeneficiaryID		= @iIDBeneficiaire
--				AND s.ConventionStateID = 'REE'	-- STATUT REEE
				AND (   u.TerminatedDate	IS NULL			-- DATE DE RÉSILIATION
				     OR u.IntReimbDate		IS NULL			-- DATE DE REMBOURSEMENT INTÉGRAL			
				    )
--				AND u.InForceDate		< @dtDateReleve	-- DATE D'ENTRÉE EN VIGUEUR DU GROUPE D'UNITÉ
		END
 
	RETURN
END
 
