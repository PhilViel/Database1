/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     : fntOPER_ObtenirEtatPaiement
Nom du service		: 
But 				: Permet d'obtenir le dernier état d'un chèque ou d'une DDD pour une ou pour toutes les opérations à une date voulue
Description		: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir l'état d'un paiement
Facette			: OPER
Référence		: 

Paramètres d’entrée	: Paramètre			        Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------

Paramètres de sortie:	Table					Champ					        Description
	  				-------------------------	--------------------------- 	---------------------------------

Exemple d'appel : 
        SELECT * 
        FROM dbo.fntOPER_ObtenirEtatPaiement (NULL, NULL, 'ALL') -- Toutes les opérations
        WHERE IdOperationFinanciere = 29118430 
        SELECT * FROM dbo.fntOPER_ObtenirEtatPaiement (25628768, NULL, 'DDD') 
        SELECT * FROM dbo.fntOPER_ObtenirEtatPaiement (27827636, NULL, 'CHQ') 
        SELECT * FROM dbo.fntOPER_ObtenirEtatPaiement (13655057, NULL, 'ALL') 

Historique des modifications:
        Date        Programmeur			Description									Référence
        ----------  ------------------  ---------------------------  				------------
        2018-02-09  Pierre-Luc Simard   Création de la fonction	
		2018-03-22	Maxime Martel		Ajout du iID_Paiement dans le order by pour
										les paiements avec la même date
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirEtatPaiement]
(
    @IdOperationFinanciere INT = NULL,
    @dtDate_Etat DATETIME,
    @cType_Paiement CHAR(3) = 'ALL'
)
RETURNS TABLE AS
RETURN (
    WITH CTE_Historique AS (
    SELECT 
        H.iID_Paiement,
        H.Type_Paiement,
        H.IdOperationFinanciere,
        H.dtDate_Etat,
        H.vcEtat_PaiementFR,
        H.vcEtat_PaiementEN,
        H.Montant,
        H.NumeroPaiement,
        H.DestinatairePaiement,
        H.InformationBancaireNumeroCompte,
        ROW_NUMBER() OVER (PARTITION BY H.IdOperationFinanciere ORDER BY dtDate_Etat DESC, iCheckHistoryID DESC) AS RNK   
    FROM dbo.fntOPER_ObtenirHistoriquePaiement (@IdOperationFinanciere, @dtDate_Etat, @cType_Paiement) H 
    ) 
    SELECT *
    FROM CTE_Historique H
    WHERE H.RNK = 1
)