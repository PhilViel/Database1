/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirConventionAdmissiblePAE
Nom du service		: 
But 				: Permet d'obtenir l'admissibilité au PAE de toutes les conventions
Description		: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir l'admissibilité d'une convention à un PAE
Facette			: CONV
Référence		: 

Paramètres d’entrée	: Paramètre			        Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------
					@iID_Convention				Non			ID de la convention pour laquelle on veut l'admissibilité, par défaut, pour tous

Paramètres de sortie:	Table					Champ					        Description
	  				-------------------------	--------------------------- 	---------------------------------
					Un_Convention			    ConventionID				    ID de la convention

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirConventionAdmissiblePAE (NULL)
        SELECT * FROM dbo.fntCONV_ObtenirConventionAdmissiblePAE (376071)
        
Historique des modifications:
        Date        Programmeur			Description						Référence
        ----------  ------------------  ---------------------------  	------------
        2017-10-18  Pierre-Luc Simard   Création de la fonction	
        2017-12-08  Pierre-Luc Simard   Ajout de la validation du 15 janvier pour le collectif
                                        Ajout de la validation sur la date de décès et l'âge des Individuel sans les activer
		2018-01-08  Simon Tanguay		CRIT-1090: Ajouter le test pour l'individuel
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirConventionAdmissiblePAE]
(
    @iID_Convention INT = NULL
)
RETURNS TABLE AS
RETURN (
	SELECT DISTINCT 
        C.ConventionID
	FROM dbo.Un_Convention C
    JOIN Un_Plan P ON C.PlanID = P.PlanID
    JOIN Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
    JOIN Mo_Human H ON H.HumanID = B.BeneficiaryID
    JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.ConventionID = C.ConventionID
    WHERE C.ConventionID = ISNULL(@iID_Convention, C.ConventionID)
        AND CS.ConventionStateID = 'REE'
        AND H.DeathDate IS NULL -- Le bénéficiaire n'est pas décédé 
        AND (
            ISNULL(B.bDevancement_AdmissibilitePAE, 0) <> 0 
            OR (P.PlanTypeID = 'COL'
                    AND (C.YearQualif < YEAR(GETDATE())
                        OR C.YearQualif = YEAR(GETDATE()) -- La nouvelle cohorte est admissible uniquement à compter du 15 janvier de l'année de qualification
                            AND GETDATE() >= CAST(STR(YEAR(GETDATE())) + '-01-15' AS DATE)
                        )
                )       
            OR (P.PlanTypeID = 'IND'
                AND DATEADD(YEAR, 16, H.BirthDate) <= GETDATE() -- Le bénéficiaire a 16 ans date d'aujourd'hui
                )
            )
    )