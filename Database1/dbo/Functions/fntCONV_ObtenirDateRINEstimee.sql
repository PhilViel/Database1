/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirDateRINEstimee
Nom du service		: 
But 				: Permet d'obtenir la date de RIN estimé des groupes d'unités
Description		: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir la date de RIN estimée d'un groupe d'unité
Facette			: CONV
Référence		: 

Paramètres d’entrée	: Paramètre			        Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------
					@iID_Unit                   Non         ID du groupe d'unités pour lequel on veut le statut, par défaut, pour tous
                    
Paramètres de sortie:	Table					    Champ					        Description
	  				    -------------------------	--------------------------- 	---------------------------------
                        Un_Unit                     UnitID                          ID du groupe d'unité
                                                    dDate_RINEstimee			    Date de RIN estimée 

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirDateRINEstimee (NULL, 0) -- Pour tous sans date ajustée
        SELECT * FROM dbo.fntCONV_ObtenirDateRINEstimee (NULL, 1) -- Pour tous avec date ajustée
        SELECT * FROM dbo.fntCONV_ObtenirDateRINEstimee (269975, 0) -- Pour un seul groupe d'unité sans date ajustée
        SELECT * FROM dbo.fntCONV_ObtenirDateRINEstimee (269975, 1) -- Pour un seul groupe d'unité avec date ajustée

Historique des modifications:
        Date        Programmeur			Description						Référence
        ----------  ------------------  ---------------------------  	------------
        2018-01-29  Pierre-Luc Simard   Création de la fonction	
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirDateRINEstimee]
(
    @iID_Unit INT,
    @bUtiliser_Date_Ajustee BIT
)
RETURNS TABLE AS
RETURN (
    WITH CTE_Unit AS (
    SELECT 
        U.UnitID,
        M.PmtByYearID,
        M.PmtQty,
        M.BenefAgeOnBegining,
        U.InForceDate,
        P.IntReimbAge,
        U.IntReimbDateAdjust,
        iAge =  CASE WHEN (ROUND(M.PmtQty / M.PmtByYearID, 0) + M.BenefAgeOnBegining) > P.IntReimbAge THEN 
		            CASE WHEN M.PmtByYearID = 1 AND M.PmtQty > 1 THEN -- Si c'est un annuel
				        P.IntReimbAge
		    	    ELSE
			    	    ROUND(M.PmtQty / M.PmtByYearID, 0) + M.BenefAgeOnBegining
		            END
		        ELSE
			        P.IntReimbAge
                END 
    FROM Un_Unit U
    JOIN Un_Modal M ON M.ModalID = U.ModalID
    JOIN Un_Plan P ON P.PlanID = M.PlanID
    WHERE U.UnitID = ISNULL(@iID_Unit, U.UnitID)
    ) 
    SELECT 
        U.UnitID,
        dDate_RINEstimee = 
            CASE WHEN @bUtiliser_Date_Ajustee = 1 AND U.IntReimbDateAdjust IS NOT NULL THEN 
		        U.IntReimbDateAdjust
	        ELSE
		        -- Si la date d'entrée en vigueur est avant le 1er mai 2006
		        CASE WHEN U.InForceDate < '05-01-2006' THEN 
		            CASE 
                        WHEN MONTH(U.InForceDate) <= 4 THEN
				            '05-01-' + CAST(YEAR(U.InForceDate) + (U.iAge - U.BenefAgeOnBegining) AS CHAR(4))
			            WHEN MONTH(U.InForceDate) > 10 THEN 
				            '05-01-' + CAST(YEAR(U.InForceDate) + (U.iAge - U.BenefAgeOnBegining) + 1 AS CHAR(4))
			        ELSE
				        '11-01-'+CAST(YEAR(U.InForceDate)+(U.iAge - U.BenefAgeOnBegining) AS CHAR(4))
                    END 
		        -- Si la date d'entrée en vigueur est égale ou supérieur au 1er mai 2006			
		        ELSE 
		        	-- 15 janv - 14 mai
			        CASE 
                        WHEN U.InForceDate >= '01-15-'+CAST(YEAR(U.InForceDate) AS CHAR(4))AND U.InForceDate <= '05-14-' + CAST(YEAR(U.InForceDate) AS CHAR(4)) THEN 
				        '05-15-' + CAST(YEAR(U.InForceDate) + (U.iAge - U.BenefAgeOnBegining) AS CHAR(4)) 
			            -- 15 mai - 14 sept 
			            WHEN U.InForceDate >= '05-15-'+CAST(YEAR(U.InForceDate) AS CHAR(4))AND U.InForceDate <= '09-14-' + CAST(YEAR(U.InForceDate) AS CHAR(4)) THEN 
				        '09-15-' + CAST(YEAR(U.InForceDate) + (U.iAge - U.BenefAgeOnBegining) AS CHAR(4))
			            --15 sept - 31 dec 
			            WHEN U.InForceDate >= '09-15-'+CAST(YEAR(U.InForceDate) AS CHAR(4))AND U.InForceDate <= '12-31-' + CAST(YEAR(U.InForceDate) AS CHAR(4)) THEN 
				        '01-15-' + CAST(YEAR(U.InForceDate) + (U.iAge - U.BenefAgeOnBegining)+1 AS CHAR(4))
			            --01 janv - 14 janv
			        ELSE
				        '01-15-' + CAST(YEAR(U.InForceDate) + (U.iAge - U.BenefAgeOnBegining) AS CHAR(4))
                    END 
		        END
	        END
    FROM CTE_Unit U
)