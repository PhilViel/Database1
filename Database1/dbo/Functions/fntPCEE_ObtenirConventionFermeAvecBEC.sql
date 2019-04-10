/***********************************************************************************************************************
Code de service :   fntPCEE_ObtenirConventionFermeAvecBEC
Nom du service	 :	1.1.1 Obtenir les conventions fermées avec BEC
But			 :	Obtenir la liste de toutes les conventions au statut 'Fermé' qui ont encore un montant de BEC
Description	 :	Ce service affiche toutes les conventions dont le statut est 'Fermé' et qui possède encore un monatant de BEC.
				Les informations affichées sont : Numéro de convention, montant de BEC et nom / prénom du bénéficiare
 
Facette         :	PCEE
Reférence		 :	Document fntPCEE_ObtenirConventionFermeAvecBEC.DOCX
 
Parametres d'entrée :
	   Parametres		   Description				                 					Obligatoire
        ----------          ------------------------------------------------------			--------------
	   S/O
 
Exemples d'appel:
			SELECT * FROM dbo.fntPCEE_ObtenirConventionFermeAvecBEC()
 
Parametres de sortie :
 
        Table               Champs                      Description
        ----------------    ------------------------    ---------------------------------------------------------------
	   @tConvFermeBEC      vcConventionNO			 Numéro de la convention
					   mMontantBEC				 Montant du BEC
					   vcNom					 Prénom + Nom du bénéficiaire
					   vcRaison				 Raison
 
Historique des modifications :
 
        Date        Programmeur			   Description
        ----------  ------------------------    ---------------------------------------------------------------
	   2009-10-16	Jean-François Gauthier	   Création de la fonction
	   2010-01-21	Jean-François Gauthier	   Modification de la vérification du "non renversé"
        2015-12-01  Steeve Picard               Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
**********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntPCEE_ObtenirConventionFermeAvecBEC]()
RETURNS @tConvFermeBEC TABLE
(
    vcConventionNO	VARCHAR(15),
    mMontantBEC	MONEY,
    vcNom			VARCHAR(75),
    vcRaison		VARCHAR(75)
)
AS
BEGIN
    INSERT INTO @tConvFermeBEC
    (
	   vcConventionNO,
	   mMontantBEC,
	   vcNom,	
	   vcRaison	
    )
    SELECT
	   c.ConventionNO,
	   SUM(ce.fCLB),
	   h.FirstName + ' ' + h.LastName,
	   'Attente réponse'
    FROM
	   dbo.Un_Convention c
        INNER JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GETDATE(), NULL) s
            ON s.conventionID = c.ConventionID
	   INNER JOIN dbo.Un_CESP	ce
		  ON ce.ConventionID = c.ConventionID
	   INNER JOIN dbo.Un_CESP400 ce4
		  ON ce4.ConventionID = c.ConventionID
	   INNER JOIN dbo.Mo_Human h
		  ON c.BeneficiaryID = h.HumanID
    WHERE
	   s.ConventionStateID = 'FRM'
	   AND
	   ce.fCLB <> 0
	   AND
	   ce4.tiCESP400TypeID = 24
	   AND
	   ce4.bCESPDemand = 1	
	   AND
	   ce4.iCESP800ID IS NULL
--	   AND
--			ce4.iReversedCESP400ID IS NULL  -- 2010-01-21 : JFG : Remplacé par le Not Exists
        AND
	   NOT EXISTS (SELECT 1 FROM dbo.Un_CESP400 u2 WHERE ce4.iCESP400ID = u2.iReversedCESP400ID AND u2.iCESP800ID IS NULL)	-- NON RENVERSÉ
	   AND
	   NOT EXISTS (SELECT 1 FROM dbo.Un_CESP900 ce9 WHERE ce9.iCESP400ID = ce4.iCESP400ID)
    GROUP BY
	   c.ConventionNO
	   ,h.FirstName + ' ' + h.LastName
 
    RETURN
END
