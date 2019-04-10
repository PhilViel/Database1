/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirStatutRINUnite
Nom du service		: 
But 				: Permet d'obtenir le statut des groupes d'unités à une date demandée pour le RIN
Description		: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir le statut d'un groupe d'unité pour le RIN
Facette			: CONV
Référence		: 

Paramètres d’entrée	: Paramètre			        Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------
					@iID_Convention				Non			ID de la convention pour laquelle on veut le statut de ses groupe d'unité, par défaut, pour tous
                    @iID_Unit                   Non         ID du groupe d'unités pour lequel on veut le statut, par défaut, pour tous
                    @dEnDateDu                  Non         Date à laquelle on veut le statut, par défaut, en date du jour

Paramètres de sortie:	Table					    Champ					        Description
	  				    -------------------------	--------------------------- 	---------------------------------
                        Un_Unit                     UnitID                          ID du groupe d'unité
                        Un_Unit                     ConventionID                    ID de la convention
                                                    iStatut_RIN			            Statut au niveau du RIN (
                                                                                        0 = Non admissible
                                                                                        1 = Admissible
                                                                                        2 = RIN partiel versé
                                                                                        3 = RIN complet versé)   

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirStatutRINUnite (NULL, NULL, GETDATE()) -- TOUS
        SELECT * FROM dbo.fntCONV_ObtenirStatutRINUnite (514249, NULL, GETDATE()) -- CONVENTION
        SELECT * FROM dbo.fntCONV_ObtenirStatutRINUnite (NULL, 755254, GETDATE()) -- GROUPE D'UNITÉS

Historique des modifications:
        Date        Programmeur			Description						Référence
        ----------  ------------------  ---------------------------  	------------
        2018-01-29  Pierre-Luc Simard   Création de la fonction	
        2018-02-08  Pierre-Luc Simard   Ajout des RIO, RIM et TRI
        2018-02-20  Pierre-Luc Simard   Validation du solde
        2018-03-13  Pierre-Luc Simard   Fournir un statut même pour les groupes d'unités ayant une TerminatedDate
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirStatutRINUnite]
(
    @iID_Convention INT,
    @iID_Unit INT,
    @dEnDateDu DATE
)
RETURNS TABLE AS
RETURN (
    WITH CTE_Unit_RIN_Complet AS (
        SELECT 
            U.UnitID
        FROM dbo.Un_Unit U
        WHERE U.UnitID = ISNULL(@iID_Unit, U.UnitID)
            AND U.ConventionID = ISNULL(@iID_Convention, U.ConventionID)
            AND ISNULL(U.IntReimbDate, '3000-01-01') <= @dEnDateDu
        ), CTE_Unit_RIN_Partiel AS (
        SELECT DISTINCT
            U.UnitID
        FROM dbo.Un_Unit U 
        LEFT JOIN CTE_Unit_RIN_Complet URC ON URC.UnitID = U.UnitID 
        JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
        JOIN Un_Oper O ON O.OperID = CT.OperID
        LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID
        LEFT JOIN Un_OperCancelation OCS ON OCS.OperSourceID = O.OperID
        WHERE U.UnitID = ISNULL(@iID_Unit, U.UnitID)
            AND U.ConventionID = ISNULL(@iID_Convention, U.ConventionID)
            AND URC.UnitID IS NULL -- N'est pas un RIN complet
            AND O.OperTypeID = 'RIN'
            AND O.OperDate <= @dEnDateDu
            AND OC.OperID IS NULL -- N'est pas une annulation
            AND OCS.OperSourceID IS NULL -- N'est pas annulé
        ), CTE_Unit_RIO_Partiel AS (-- RIO, RIM et TRI
        SELECT DISTINCT 
            U.UnitID
        FROM dbo.Un_Unit U 
        LEFT JOIN CTE_Unit_RIN_Complet URC ON URC.UnitID = U.UnitID
        JOIN tblOPER_OperationsRIO R ON R.iID_Unite_Source = U.UnitID
        JOIN Un_Oper O ON O.OperID = R.iID_Oper_RIO
        WHERE U.UnitID = ISNULL(@iID_Unit, U.UnitID)
            AND U.ConventionID = ISNULL(@iID_Convention, U.ConventionID)
            AND URC.UnitID IS NULL -- N'est pas un RIN complet
            AND R.bRIO_Annulee = 0 -- N'est pas annulé
            AND R.bRIO_QuiAnnule = 0 -- N'est pas une annulation
            AND O.OperDate <= @dEnDateDu
        ), CTE_Unit_RIN_Partiel_Solde AS (
        SELECT 
            U.UnitID,
            Cotisation = SUM(CT.Cotisation),
            Frais = SUM(CT.Fee)
        FROM (
            SELECT DISTINCT
                U.UnitID
            FROM dbo.Un_Unit U 
            LEFT JOIN CTE_Unit_RIN_Partiel URP ON URP.UnitID = U.UnitID 
            LEFT JOIN CTE_Unit_RIO_Partiel URIO ON URIO.UnitID = U.UnitID 
            WHERE (URP.UnitID IS NOT NULL 
                    OR URIO.UnitID IS NOT NULL)             
            ) U 
        JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
        JOIN Un_Oper O ON O.OperID = CT.OperID
        WHERE O.OperDate <= @dEnDateDu
        GROUP BY U.UnitID
        ), CTE_Unit_RIN_Admissible AS (
        SELECT 
            U.UnitID,
            URD.dDate_RINEstimee
        FROM dbo.Un_Unit U
        LEFT JOIN CTE_Unit_RIN_Complet URC ON URC.UnitID = U.UnitID 
        LEFT JOIN CTE_Unit_RIN_Partiel URP ON URP.UnitID = U.UnitID 
        LEFT JOIN CTE_Unit_RIO_Partiel URIO ON URIO.UnitID = U.UnitID 
        JOIN dbo.fntCONV_ObtenirDateRINEstimee (NULL, 1) URD ON URD.UnitID = U.UnitID
        WHERE U.UnitID = ISNULL(@iID_Unit, U.UnitID)
            AND U.ConventionID = ISNULL(@iID_Convention, U.ConventionID)
            AND URC.UnitID IS NULL -- N'est pas un RIN complet
            AND URP.UnitID IS NULL -- N'est pas un RIN partiel
            AND URIO.UnitID IS NULL -- N'est pas un RIO partiel
            AND U.TerminatedDate IS NULL 
            AND URD.dDate_RINEstimee < @dEnDateDu
        )
        SELECT 
            U.UnitID,
            U.ConventionID,
            iStatut_RIN = CASE 
                            WHEN URC.UnitID IS NOT NULL THEN 3 -- Complet
                            WHEN (URP.UnitID IS NOT NULL OR URIO.UnitID IS NOT NULL) AND C.PlanID <> 4 AND ISNULL(URPS.Cotisation, 0) = 0 AND ISNULL(URPS.Frais, 0) = 0 THEN 3 -- Collectif complet
                            WHEN (URP.UnitID IS NOT NULL OR URIO.UnitID IS NOT NULL) AND C.PlanID = 4 AND ISNULL(URPS.Cotisation, 0) = 0 THEN 3 -- Individuel complet
                            WHEN URP.UnitID IS NOT NULL OR URIO.UnitID IS NOT NULL THEN 2 -- Partiel
                            WHEN URA.UnitID IS NOT NULL THEN 1 -- Admissible
                          ELSE 0 -- Non admissible
                          END,
            U.TerminatedDate                        
        FROM dbo.Un_Unit U
        JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
        LEFT JOIN CTE_Unit_RIN_Complet URC ON URC.UnitID = U.UnitID
        LEFT JOIN CTE_Unit_RIN_Partiel URP ON URP.UnitID = U.UnitID
        LEFT JOIN CTE_Unit_RIO_Partiel URIO ON URIO.UnitID = U.UnitID
        LEFT JOIN CTE_Unit_RIN_Admissible URA ON URA.UnitID = U.UnitID 
        LEFT JOIN CTE_Unit_RIN_Partiel_Solde URPS ON URPS.UnitID = ISNULL(URP.UnitID, URIO.UnitID)  
        WHERE U.UnitID = ISNULL(@iID_Unit, U.UnitID)
            AND U.ConventionID = ISNULL(@iID_Convention, U.ConventionID)
            AND (U.TerminatedDate IS NULL
                OR (U.TerminatedDate IS NOT NULL AND U.IntReimbDate IS NOT NULL))

)