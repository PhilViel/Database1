
/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psREPR_ObtenirCumulatifsGreatPlains
Nom du service		: Obtenir le cumulatif des COMDIF
But 				: Obtenir le cumulatif à une date donnée du type d'opération COMDIF pour chaque représentant

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						dtEndGP						Date à laquelle on désire obtenir le cumulatif

Exemple d’appel		:	EXECUTE psREPR_ObtenirCumulatifsGreatPlains '2016-06-01'

Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------- -----------------------------------------	------------
		2011-06-08		Pierre-Luc Simard	Création du service				
		2016-02-22		Pierre-Luc Simard	Changement de serveur		
        2016-06-09      Pierre-Luc Simard   Renommer la procédure GUI.dbo.psGP_ObtenirCumCOMDIF pour psREPR_ObtenirCumulatifsGreatPlains
                                            Ajout des COMFIX
        2016-06-21      Pierre-Luc Simard   Conversion en requête dynamique pour éviter les problèmes de DTC lors des déploiements
		2018-10-05		Donald Huppé		Ajout de DUIPAD (jira prod-12208)
*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psREPR_ObtenirCumulatifsGreatPlains]
    (
		@dtEndGP DATE  
    )
AS 
BEGIN
    DECLARE 
        @SQL VARCHAR(5000)
        PRINT CAST(@dtEndGP AS VARCHAR(50))
        SET @SQL = 'SELECT
		                CPY10100.PEmployeeID, 
		                CPY10100.PLastName, 
		                CPY10100.PFirstName,
		                COMDIF = SUM(CASE WHEN CPY30260.PIncomeCode = ''COMDIF'' THEN CPY30260.PLineTotal ELSE 0 END),
                        COMFIX = SUM(CASE WHEN CPY30260.PIncomeCode = ''COMFIX'' THEN CPY30260.PLineTotal ELSE 0 END),
						DUIPAD = SUM(CASE WHEN CPY30260.PIncomeCode = ''DUIPAD'' THEN CPY30260.PLineTotal ELSE 0 END)
	                FROM [SRVGP05].[GESTI].dbo.VGU_CPY10101 CPY10101 
	                JOIN [SRVGP05].[GESTI].dbo.VGU_CPY10100 CPY10100 ON CPY10101.PEmployeeID = CPY10100.PEmployeeID                   
	                LEFT JOIN [SRVGP05].[GESTI].dbo.VGU_CPY30260 CPY30260 ON CPY10100.PEmployeeID = CPY30260.PEmployeeID       
	                JOIN [SRVGP05].[GESTI].dbo.VGU_CPY30010 CPY30010 ON CPY30010.BACHNUMB = CPY30260.BACHNUMB	
	                WHERE CPY10100.PEmployeeClass = ''REP''    
		                AND CPY30260.PIncomeCode IN (''COMDIF'', ''COMFIX'', ''DUIPAD'')   
		                AND CPY30010.PChequeDate <= ''' + CAST(@dtEndGP AS VARCHAR(10)) + ''' 
	                GROUP BY
		                CPY10100.PEmployeeID, 
		                CPY10100.PLastName, 
		                CPY10100.PFirstName
	                ORDER BY
		                CPY10100.PEmployeeID, 
		                CPY10100.PLastName, 
		                CPY10100.PFirstName'
        EXEC (@SQL)
END

