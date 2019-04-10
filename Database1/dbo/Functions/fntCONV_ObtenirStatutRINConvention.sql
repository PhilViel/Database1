/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirStatutRINConvention
Nom du service		: 
But 				: Permet d'obtenir le statut des conventions à une date demandée pour le RIN, en se basant sur le statut des unités pour le RIN
Description		: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir le statut d'une convention pour le RIN
Facette			: CONV
Référence		: 

Paramètres d’entrée	: Paramètre			        Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------
					@iID_Convention				Non			ID de la convention pour laquelle on veut le statut, par défaut, pour tous
                    @dEnDateDu                  Non         Date à laquelle on veut le statut, par défaut, en date du jour

Paramètres de sortie:	Table					    Champ					        Description
	  				    -------------------------	--------------------------- 	---------------------------------
                        Un_Unit                     ConventionID                    ID de la convention
                                                    iStatut_RIN			            Statut de la convention au niveau du RIN (
                                                                                        0 = Non admissible
                                                                                        1 = Admissible
                                                                                        2 = RIN partiel versé
                                                                                        3 = RIN complet versé)   

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirStatutRINConvention (NULL, GETDATE()) -- TOUS
        SELECT * FROM dbo.fntCONV_ObtenirStatutRINConvention (514249, GETDATE()) -- CONVENTION

Historique des modifications:
        Date        Programmeur			Description						Référence
        ----------  ------------------  ---------------------------  	------------
        2018-01-29  Pierre-Luc Simard   Création de la fonction	
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirStatutRINConvention]
(
    @iID_Convention INT,
    @dEnDateDu DATE
)
RETURNS TABLE AS
RETURN (
    SELECT 
        U.ConventionID,
        iStatut_RIN =   CASE 
                            WHEN MAX(U.iStatut_RIN) = 0 THEN 0 -- Non Admissible au RIN
                            WHEN MIN(U.iStatut_RIN) > 0 AND MAX(U.iStatut_RIN) = 1 THEN 1 -- Admissible au RIN
                            WHEN MIN(U.iStatut_RIN) = 3 THEN 3 -- RIN Complet
                            WHEN MIN(U.iStatut_RIN) > 0 AND MAX(U.iStatut_RIN) > 1 THEN 2 -- RIN Partiel
                        ELSE 0
                        END 
    FROM dbo.fntCONV_ObtenirStatutRINUnite (@iID_Convention, NULL, @dEnDateDu) U
    GROUP BY U.ConventionID
)