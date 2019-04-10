/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirUniteAvecRIN
Nom du service		: 
But 				: Permet d'obtenir les groupe d'unités ayant reçu un RIN, partiel ou complet
Description		: Cette fonction est appelée à chaque fois qu'il est nécessaire d'obtenir les groupes d'unités ayant un RIN partiel ou complet
Facette			: CONV
Référence		: 

Paramètres d’entrée	: Paramètre			        Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------
					@iID_Convention				Non			ID de la convention pour laquelle on veut déterminer si les groupes d'unités ont reçu un RIN, par défaut, pour tous
                    @iID_Unit                   Non         ID du groupe d'unités pour lequel on veut déterminer s'il a reçu un RIN, par défaut, pour tous
                    @dEnDateDu                  Non         Date à laquelle on veut déterminer si les groupes d'unités ont reçu un RIN, par défaut, en date du jour

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
        SELECT * FROM dbo.fntCONV_ObtenirUniteAvecRIN (NULL, NULL, GETDATE()) -- TOUS
        SELECT * FROM dbo.fntCONV_ObtenirUniteAvecRIN (514249, NULL, GETDATE()) -- CONVENTION
        SELECT * FROM dbo.fntCONV_ObtenirUniteAvecRIN (NULL, 250839, GETDATE()) -- GROUPE D'UNITÉS

Historique des modifications:
        Date        Programmeur			Description						Référence
        ----------  ------------------  ---------------------------  	------------
        2018-12-05  Pierre-Luc Simard   Création de la fonction	
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirUniteAvecRIN]
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
        )
        SELECT 
            U.UnitID
        FROM dbo.Un_Unit U
        JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
        LEFT JOIN CTE_Unit_RIN_Complet URC ON URC.UnitID = U.UnitID
        LEFT JOIN CTE_Unit_RIN_Partiel URP ON URP.UnitID = U.UnitID
        LEFT JOIN CTE_Unit_RIO_Partiel URIO ON URIO.UnitID = U.UnitID
        WHERE U.UnitID = ISNULL(@iID_Unit, U.UnitID)
            AND U.ConventionID = ISNULL(@iID_Convention, U.ConventionID)
            AND (U.TerminatedDate IS NULL
                OR (U.TerminatedDate IS NOT NULL AND U.IntReimbDate IS NOT NULL))
            AND (URC.UnitID IS NOT NULL OR URP.UnitID IS NOT NULL OR URIO.UnitID IS NOT NULL)

)
