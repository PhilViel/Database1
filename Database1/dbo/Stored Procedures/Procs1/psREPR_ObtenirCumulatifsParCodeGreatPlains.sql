/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psREPR_ObtenirCumulatifsParCodeGreatPlains
Nom du service		: Obtenir le cumulatif par code de paie
But 				: Obtenir le cumulatif par code de paie pour une année donnée pour chaque représentant 

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@iAnnee						Année pour laquelle on désire obtenir le cumulatif par code de paie

Exemple d’appel		:	EXECUTE psREPR_ObtenirCumulatifsParCodeGreatPlains '2018-01-01', '2018-09-30'
						DROP TABLE ##TMP1

Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------- -----------------------------------------	------------
		2018-10-19		Pierre-Luc Simard	Création du service				
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ObtenirCumulatifsParCodeGreatPlains]
    (
	@dtStartDate DATETIME = '2018-01-01',
	@dtEndDate DATETIME = '2018-10-15'
		--@iAnnee INT   
    )
AS 
BEGIN	

    DECLARE 
        @SQL VARCHAR(5000)
        SET @SQL = '

	SELECT *
	INTO ##TMP1 
	FROM (
		-- PÉRIODE demandée
		SELECT
			CPY10100.PEmployeeID, 
			CPY10100.PLastName, 
			CPY10100.PFirstName,
			PIncomeCode_ID =	CASE 
								WHEN CPY30260.PIncomeCode = ''AVRESI'' THEN 2 --annee en cours
								WHEN CPY30260.PIncomeCode = ''AVCSPE'' THEN 5 --annee en cours
								ELSE 100
								END,
			CPY30260.PIncomeCode,
			GL00105.ACTNUMST,
			PDescription = 	LTRIM(RTRIM(CPY10060.PDescription)),
			CPY10060.PPayrollCodeType,
			TypeCode =  CASE 
							WHEN CPY10060.PPayrollCodeType = 1 THEN ''Revenus'' 
							WHEN CPY10060.PPayrollCodeType = 2 THEN ''Avantages imposables et autres avantages'' 
							WHEN CPY10060.PPayrollCodeType = 3 THEN ''Retenues''
							ELSE ''Autres''
						END,          
			PLineTotal = SUM(CPY30260.PLineTotal)
		FROM [SRVGP05].[GESTI].dbo.VGU_CPY10101 CPY10101 
		JOIN [SRVGP05].[GESTI].dbo.VGU_CPY10100 CPY10100 ON CPY10101.PEmployeeID = CPY10100.PEmployeeID                   
		JOIN [SRVGP05].[GESTI].dbo.VGU_CPY30260 CPY30260 ON CPY10100.PEmployeeID = CPY30260.PEmployeeID       
		JOIN [SRVGP05].[GESTI].dbo.VGU_CPY10060 CPY10060 ON CPY10060.PIncomeCode = CPY30260.PIncomeCode
		JOIN [SRVGP05].[GESTI].dbo.VGU_CPY30010 CPY30010 ON CPY30010.BACHNUMB = CPY30260.BACHNUMB	
		LEFT JOIN [SRVGP05].[GESTI].dbo.VGU_GL00105 GL00105	 ON GL00105.ACTINDX = CPY10060.PDebitAccountIndex OR GL00105.ACTINDX = CPY10060.PCreditAccountIndex -- SELECT	* FROM VGU_GL00105
		WHERE CPY10100.PEmployeeClass = ''REP''    
			--AND YEAR(CPY30010.PChequeDate) = 2018 
			AND CPY30010.PChequeDate BETWEEN ''' + LEFT(CONVERT(VARCHAR, @dtStartDate, 120), 10) + ''' AND ''' + LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10) + '''  --LEFT(CONVERT(VARCHAR, @dtStartDate, 120), 10) AND LEFT(CONVERT(VARCHAR, @dtEndDate, 120), 10)
		GROUP BY
			CPY10100.PEmployeeID, 
			CPY10100.PLastName, 
			CPY10100.PFirstName,
			CASE 
			WHEN CPY30260.PIncomeCode = ''AVRESI'' THEN 2 
			WHEN CPY30260.PIncomeCode = ''AVCSPE'' THEN 5
			ELSE 100
			END,
			CPY30260.PIncomeCode,
			GL00105.ACTNUMST,
			LTRIM(RTRIM(CPY10060.PDescription)),
			CPY10060.PPayrollCodeType,
			CASE 
				WHEN CPY10060.PPayrollCodeType = 1 THEN ''Revenus'' 
				WHEN CPY10060.PPayrollCodeType = 2 THEN ''Avantages imposables et autres avantages'' 
				WHEN CPY10060.PPayrollCodeType = 3 THEN ''Retenues''
				ELSE ''Autres''
			END

		UNION ALL

		-- Annee précédente POUR AVRESI ET AVCSPE seulement
		SELECT
			CPY10100.PEmployeeID, 
			CPY10100.PLastName, 
			CPY10100.PFirstName,
			PIncomeCode_ID =	CASE 
								WHEN CPY50260.PIncomeCode = ''AVRESI'' THEN 1 --annee préc
								WHEN CPY50260.PIncomeCode = ''AVCSPE'' THEN 4 --annee préc 
								ELSE 100
								END,
			CPY50260.PIncomeCode,
			GL00105.ACTNUMST,
			PDescription = 	LTRIM(RTRIM(CPY10060.PDescription)),
			CPY10060.PPayrollCodeType,
			TypeCode =  CASE 
							WHEN CPY10060.PPayrollCodeType = 1 THEN ''Revenus'' 
							WHEN CPY10060.PPayrollCodeType = 2 THEN ''Avantages imposables et autres avantages'' 
							WHEN CPY10060.PPayrollCodeType = 3 THEN ''Retenues''
							ELSE ''Autres''
						END,          
			PLineTotal = SUM(CPY50260.PLineTotal)
		FROM [SRVGP05].[GESTI].dbo.VGU_CPY10101 CPY10101 
		JOIN [SRVGP05].[GESTI].dbo.VGU_CPY10100 CPY10100 ON CPY10101.PEmployeeID = CPY10100.PEmployeeID                   
		JOIN [SRVGP05].[GESTI].dbo.VGU_CPY50260 CPY50260 ON CPY10100.PEmployeeID = CPY50260.PEmployeeID       
		JOIN [SRVGP05].[GESTI].dbo.VGU_CPY10060 CPY10060 ON CPY10060.PIncomeCode = CPY50260.PIncomeCode
		JOIN [SRVGP05].[GESTI].dbo.VGU_CPY60310 CPY60310 ON CPY60310.BACHNUMB = CPY50260.BACHNUMB	
		LEFT JOIN [SRVGP05].[GESTI].dbo.VGU_GL00105 GL00105	 ON GL00105.ACTINDX = CPY10060.PDebitAccountIndex OR GL00105.ACTINDX = CPY10060.PCreditAccountIndex
		WHERE CPY10100.PEmployeeClass = ''REP''    
			AND YEAR(CPY60310.PChequeDate) = ' + cast(YEAR(@dtStartDate) - 1 as VARCHAR) + ' 
			AND CPY50260.PIncomeCode in (''AVRESI'',''AVCSPE'')
		GROUP BY
			CPY10100.PEmployeeID, 
			CPY10100.PLastName, 
			CPY10100.PFirstName,
			CASE 
			WHEN CPY50260.PIncomeCode = ''AVRESI'' THEN 1 
			WHEN CPY50260.PIncomeCode = ''AVCSPE'' THEN 4
			ELSE 100
			END,
			CPY50260.PIncomeCode,
			GL00105.ACTNUMST,
			LTRIM(RTRIM(CPY10060.PDescription)),
			CPY10060.PPayrollCodeType,
			CASE 
				WHEN CPY10060.PPayrollCodeType = 1 THEN ''Revenus'' 
				WHEN CPY10060.PPayrollCodeType = 2 THEN ''Avantages imposables et autres avantages'' 
				WHEN CPY10060.PPayrollCodeType = 3 THEN ''Retenues''
				ELSE ''Autres''
			END
		)V'

	EXEC (@SQL)
	print @SQL

	SELECT 
		PEmployeeID, 
		PLastName, 
		PFirstName,
		PIncomeCode_ID,
		PIncomeCode,
		ACTNUMST = LTRIM(RTRIM(ACTNUMST)),
		PDescription = PDescription + CASE WHEN PIncomeCode_ID IN (1,4) THEN CHAR(10) + '(année précédente)' ELSE '' END,
		PPayrollCodeType,
		TypeCode = LTRIM(RTRIM(TypeCode)),
		PLineTotal = 1.00 * CAST(SUM(PLineTotal) AS MONEY)
	FROM (
		SELECT 
			PEmployeeID, 
			PLastName, 
			PFirstName,
			PIncomeCode_ID,
			PIncomeCode,
			ACTNUMST,
			PDescription,
			PPayrollCodeType,
			TypeCode,          
			PLineTotal
		FROM ##TMP1

		UNION ALL

		-- VALEUR PAR FEFAUT À TOUT CEUX QUI ONT CE CODE DANS LA PÉRIODE DEMANDÉE
		SELECT DISTINCT
			PEmployeeID, 
			PLastName, 
			PFirstName,
			PIncomeCode_ID = 1, -- ANNÉÉE PRÉCÉDENTE
			PIncomeCode,
			ACTNUMST,
			PDescription = 	LTRIM(RTRIM(PDescription)),
			PPayrollCodeType,
			TypeCode,          
			PLineTotal = 0
		FROM ##TMP1
		WHERE PIncomeCode = 'AVRESI'

		UNION ALL

		SELECT 
			PEmployeeID, 
			PLastName, 
			PFirstName,
			PIncomeCode_ID = 3,
			PIncomeCode,
			ACTNUMST,
			PDescription = 'Solde' + CHAR(10) + PDescription,
			PPayrollCodeType,
			TypeCode,          
			PLineTotal = SUM(PLineTotal)
		FROM ##TMP1
		WHERE PIncomeCode_ID IN (1,2)
		GROUP BY
			PEmployeeID, 
			PLastName, 
			PFirstName,
			PIncomeCode,
			ACTNUMST,
			'Solde' + CHAR(10) + PDescription,
			PPayrollCodeType,
			TypeCode


		UNION ALL

		SELECT 
			PEmployeeID, 
			PLastName, 
			PFirstName,
			PIncomeCode_ID = 6,
			PIncomeCode,
			ACTNUMST,
			PDescription = 'Solde' + CHAR(10) + PDescription,
			PPayrollCodeType,
			TypeCode,          
			PLineTotal = SUM(PLineTotal)
		FROM ##TMP1
		WHERE PIncomeCode_ID IN (4,5)
		GROUP BY
			PEmployeeID, 
			PLastName, 
			PFirstName,
			--PIncomeCode_ID = 3,
			PIncomeCode,
			ACTNUMST,
			'Solde' + CHAR(10) + PDescription,
			PPayrollCodeType,
			TypeCode
		)V2
	GROUP BY
		PEmployeeID, 
		PLastName, 
		PFirstName,
		PIncomeCode_ID,
		PIncomeCode,
		ACTNUMST,
		PDescription,
		PPayrollCodeType,
		TypeCode
	ORDER BY	
		PEmployeeID,PIncomeCode_ID


	drop table ##TMP1
/*
    DECLARE 
        @SQL VARCHAR(5000)
        SET @SQL = 'SELECT
	                    CPY10100.PEmployeeID, 
	                    CPY10100.PLastName, 
	                    CPY10100.PFirstName,
	                    CPY30260.PIncomeCode,
                        TypeCode =  CASE 
                                        WHEN CPY10060.PPayrollCodeType = 1 THEN ''Revenus'' 
                                        WHEN CPY10060.PPayrollCodeType = 2 THEN ''Avantages imposables et autres avantages'' 
                                        WHEN CPY10060.PPayrollCodeType = 3 THEN ''Retenues''
                                        ELSE ''Autres''
                                    END,          
                        SUM(CPY30260.PLineTotal)
                    FROM [SRVGP05].[GESTI].dbo.VGU_CPY10101 CPY10101 
                    JOIN [SRVGP05].[GESTI].dbo.VGU_CPY10100 CPY10100 ON CPY10101.PEmployeeID = CPY10100.PEmployeeID                   
                    JOIN [SRVGP05].[GESTI].dbo.VGU_CPY30260 CPY30260 ON CPY10100.PEmployeeID = CPY30260.PEmployeeID       
                    JOIN [SRVGP05].[GESTI].dbo.VGU_CPY10060 CPY10060 ON CPY10060.PIncomeCode = CPY30260.PIncomeCode
                    JOIN [SRVGP05].[GESTI].dbo.VGU_CPY30010 CPY30010 ON CPY30010.BACHNUMB = CPY30260.BACHNUMB	
                    WHERE CPY10100.PEmployeeClass = ''REP''    
	                    AND YEAR(CPY30010.PChequeDate) = ''' + CAST(@iAnnee AS VARCHAR(10)) + ''' 
                    GROUP BY
	                    CPY10100.PEmployeeID, 
	                    CPY10100.PLastName, 
	                    CPY10100.PFirstName,
                        CPY30260.PIncomeCode,
                        CASE 
                            WHEN CPY10060.PPayrollCodeType = 1 THEN ''Revenus'' 
                            WHEN CPY10060.PPayrollCodeType = 2 THEN ''Avantages imposables et autres avantages'' 
                            WHEN CPY10060.PPayrollCodeType = 3 THEN ''Retenues''
                            ELSE ''Autres''
                        END
                    ORDER BY
	                    CPY10100.PEmployeeID, 
	                    CPY10100.PLastName, 
	                    CPY10100.PFirstName,
                        CPY30260.PIncomeCode'
        EXEC (@SQL)
		*/
END
