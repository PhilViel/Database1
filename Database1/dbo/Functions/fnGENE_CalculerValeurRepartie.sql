/****************************************************************************************************
Code de service		:		fnGENE_CalculerValeurRepartie
Nom du service		:		fnGENE_CalculerValeurRepartie
But					:		Calculer la répartition d'une valeur en parts égales, en distribuant les écarts dans les premiers ou les derniers éléments
Facette				:		GENE
Reférence			:		UniAccès-Noyau-GENE

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        @mValeurTotal               Valeur total à répartir
                        @iQuantite                  Quantité de parts dans lesquelles faire la répartition
                        @iPosition                  Position demandée
                        @iPrecision                 Nombre de virgule pour l'arrondi des valeur (Entre 0 et 4)
                        @bRepartirFin               Indique si on veut répartir au début (0) ou à la fin (1) les plsu grosses valeurs

Exemple d'appel:        --Pour 2 unités divisés en 3 PAE au début:
                        SELECT *, dbo.fnGENE_CalculerValeurRepartie(1, 3, R.RowID, 3, 0)
                        FROM (SELECT RowID = 1 UNION SELECT RowID = 2 UNION SELECT RowID = 3) R
                        --Pour 2 unités divisés en 3 PAE à la fin:
                        SELECT *, dbo.fnGENE_CalculerValeurRepartie(1, 3, R.RowID, 3, 1)
                        FROM (SELECT RowID = 1 UNION SELECT RowID = 2 UNION SELECT RowID = 3) R

Parametres de sortie : La valeur répartie pour la position demandée

Historique des modifications :
			
		Date		Programmeur			Description						
		----------	------------------  -----------------------------------------
		2018-11-26  Pierre-Luc Simard   Création de la fonction
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_CalculerValeurRepartie](	
    @mValeurTotal AS MONEY,
    @iQuantite AS INT,
    @iPosition AS INT,
    @iPrecision AS INT,
    @bRepartirFin AS BIT)
RETURNS MONEY
AS
BEGIN
    DECLARE 
        @mValeurMinimal AS MONEY,
        @mValeur AS MONEY,
        @iEcart AS INT,
        @iChiffreUn AS MONEY = 1

    -- Calculer la valeurs minimale en divisant la valeur total par la quantité demandée et en tronquant les résultats à l'arrondi demandé
    SET @mValeurMinimal = ROUND(@mValeurTotal / @iQuantite, @iPrecision, 1)
    -- Calculer le nombre de valeurs dans lesquelles on doit répartir l'écart 
    SET @iEcart = (@mValeurTotal - @mValeurMinimal * @iQuantite) * CAST('1' + REPLICATE(0, @iPrecision) AS INT)
    -- Calculer la valeur selon la position demandée et la répartition demandée 
    SET @mValeur =  CASE WHEN ISNULL(@bRepartirFin, 1) = 1 THEN 
                        -- Pour répartir à la fin
                        CASE WHEN @iPosition > @iQuantite - @iEcart THEN @mValeurMinimal + (@iChiffreUn / CAST('1' + REPLICATE(0, @iPrecision) AS INT)) ELSE @mValeurMinimal END
                    ELSE 
                        -- Pour répartir au début
                        CASE WHEN @iPosition <= @iEcart THEN @mValeurMinimal + (@iChiffreUn / CAST('1' + REPLICATE(0, @iPrecision) AS INT)) ELSE @mValeurMinimal END
                    END 
	
	RETURN ISNULL(@mValeur,0)
END