/********************************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc.

Code du service		: psCONV_RapportVenteUnborn
Nom du service		: Rapport des ventes unborn
But 				: 
Facette				: 

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportVenteUnborn NULL, NULL, NULL, NULL, NULL, NULL

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-09-19	    Maxime Martel						Création du service	
		
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportVenteUnborn] (
    @PrenomRep varchar(100) = NULL,
	@NomRep varchar(100) = NULL,
    @PrenomDir varchar(100) = NULL,
    @NomDir varchar(100) = NULL,
	@dtDateSignature datetime = NULL,
	@dtDateReception datetime = NULL
    )
AS
BEGIN
      declare @SQL VARCHAR(2000)

      IF @NomRep = ''
         SET @NomRep = NULL

      IF @NomDir = ''
         SET @NomDir = NULL

      IF @PrenomRep = ''
         SET @PrenomRep = NULL

      IF @PrenomDir = ''
         SET @PrenomDir = NULL

      IF @dtDateSignature = ''
         SET @dtDateSignature = NULL

      IF @dtDateReception = ''
         SET @dtDateReception = NULL
      

      CREATE TABLE #Tmp
      (
         output nvarchar(max)
      )
   
      SET @SQL = 'sqlcmd -E -S ' + dbo.fnGENE_ObtenirParametre('GENE_SERVEUR_PROPELECT', NULL, NULL, NULL, NULL, NULL, NULL) + ' -d ' + dbo.fnGENE_ObtenirParametre('GENE_BD_PROPELECT', NULL, NULL, NULL, NULL, NULL, NULL) + ' -Q "exec dbo.psCONV_ObtenirVentesUnborn" -h-1 -W -s ;'
      INSERT INTO #Tmp
      EXEC xp_cmdshell @SQL;  
         
      SELECT
         TransactionID = CAST(dbo.fn_GetValueInString(output, 1, ';') as bigint),
         RFirstName = dbo.fn_GetValueInString(output, 2, ';'),
         RLastName = dbo.fn_GetValueInString(output, 3, ';'),
         RProAccesID = CAST(dbo.fn_GetValueInString(output, 4, ';') as int),
         SFirstName = dbo.fn_GetValueInString(output, 5, ';'),
         SLastName = dbo.fn_GetValueInString(output, 6, ';'),
         TransactionDateTime = CAST(dbo.fn_GetValueInString(output, 7, ';') as datetime),
         SignedDate = CAST(dbo.fn_GetValueInString(output, 8, ';') as datetime),
         HomePhone = dbo.fn_GetValueInString(output, 9, ';'),
         WorkPhone = dbo.fn_GetValueInString(output, 10, ';'),
         WorkPhoneExtension = dbo.fn_GetValueInString(output, 11, ';'),
         CellPhone = dbo.fn_GetValueInString(output, 12, ';')
      into #dataPropElect
      from #tmp
      where output is not null

      SELECT t.*, DFirstName = DH.FirstName, DLastName = DH.LastName  
      FROM #dataPropElect T 
      JOIN (
               SELECT
	                 BossID = MAX(BossID), RB.RepID
               FROM 
                  Un_RepBossHist RB
                  JOIN (
		                SELECT
			               RepID,
			               RepBossPct = MAX(RepBossPct)
		                FROM 
			               Un_RepBossHist RB
		                WHERE 
			               RepRoleID = 'DIR'
			               AND StartDate IS NOT NULL
			               AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
			               AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
		                GROUP BY
			                  RepID
		                ) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
               WHERE RB.RepRoleID = 'DIR'
	                 AND RB.StartDate IS NOT NULL
	                 AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
	                 AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
               GROUP BY
	                 RB.RepID
            ) DIR on DIR.RepID = T.RProAccesID 
      JOIN Mo_human DH on DH.HumanID = DIR.BossID
      JOIN Mo_human RH on RH.HumanID = T.RProAccesID
      WHERE    
         (@NomDir = DH.LastName OR @NomDir is null)
         AND (@PrenomDir = DH.FirstName OR @PrenomDir is null)
         AND (@NomRep = T.RLastName OR @NomRep is null)
         AND (@PrenomRep = T.RFirstName OR @PrenomRep is null)
         AND (Convert(varchar(10), @dtDateSignature,120)  = Convert(varchar(10), T.SignedDate,120) OR @dtDateSignature is null)
         AND (Convert(varchar(10), @dtDateReception,120) = Convert(varchar(10), T.TransactionDateTime,120) OR @dtDateReception is null)
      
END
