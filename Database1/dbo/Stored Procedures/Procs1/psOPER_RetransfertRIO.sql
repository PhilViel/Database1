--WAITFOR TIME '18:00';

/*
- La génération d'un RIO ne transfert pas les soldes de capital d'IQEE négatif.  Mais on ne les traitera pas de toute façon. On exclu les convention qui on IQEE < 0 OU IQEE+ < 0
- Il y a peu de convention collective avec solde de capital PCEE, qui ne sont pas traité environ 100)
exec psOPER_RetransfertRIO
*/

CREATE PROCEDURE dbo.psOPER_RetransfertRIO as
begin

SET NOCOUNT ON

DECLARE @tblConvRio TABLE	(
		 iID_Convention_Source		INT
		,vcConventionNoSource				varchar(15)
		,iID_Unite_Source			INT
		,OperTypeID					VARCHAR(3)
		)

DECLARE @iID_Convention_Source INT,
		@vcConventionNoSource varchar(15),
		@iID_Unite_Source INT,
		@dtDateDuJour DATETIME,
		@vcRIO_TRANSFERT_TRANSAC_CONVENTION VARCHAR(200),
		@iID_Connexion INT
		,@OperTypeID	VARCHAR(3) -- FT1
		,@iID_Convention_Cible INT -- FT2
		,@iConnectId INT
		,@MaxOperID INT
		,@iElligible int
		,@i int
		
SELECT 
	@MaxOperID = MAX(OperID) 
FROM Un_Oper
		
if exists ( SELECT name from sysobjects where name = 'tbl_TEMPRetransfertRIO')
	begin
		drop TABLE tbl_TEMPRetransfertRIO
	end

CREATE table tbl_TEMPRetransfertRIO (conventionno varchar(15))

		--SELECT * from tbl_TEMPRetransfertRIO
/*
1341034
1341042
1416513
1573693
2016125
*/		
SET @vcRIO_TRANSFERT_TRANSAC_CONVENTION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')
-- select [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')
SET @dtDateDuJour = GETDATE()

--- RÉCUPÉRATION DU CONNECTID SYSTÈME À PARTIR DE LA TABLE UN_DEF
SELECT
	@iConnectId = d.iID_Utilisateur_Systeme 
FROM 
	dbo.Un_Def d

	INSERT INTO @tblConvRio	(
							 iID_Convention_Source	
							,vcConventionNoSource
							,iID_Unite_Source		
							,OperTypeID -- FT1
							)
							
	SELECT DISTINCT R.iID_Convention_Source
					,C.ConventionNo
					,R.iID_Unite_Source
					,R.OperTypeID -- FT1
	
	FROM tblOPER_OperationsRIO R
	JOIN dbo.Un_Convention c ON R.iID_Convention_Source = c.ConventionID --and c.ConventionNo = 'C-20000306011'
	
	WHERE R.bRIO_Annulee = 0
	  AND R.bRIO_QuiAnnule = 0
	  AND R.dtDate_Enregistrement = (SELECT MIN(R2.dtDate_Enregistrement)
									 FROM tblOPER_OperationsRIO R2
									 WHERE R2.iID_Convention_Source = R.iID_Convention_Source AND
										   R2.bRIO_Annulee = 0 AND
										   R2.bRIO_QuiAnnule = 0)
	  -- qui ont un solde transférable par le RIO...
	  AND 0 < (SELECT ISNULL(SUM(OC.ConventionOperAmount),0)
				FROM dbo.Un_ConventionOper OC
				WHERE OC.ConventionID = R.iID_Convention_Source
				  AND (CHARINDEX(OC.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0))

		-- qui ont de la subvention d'IQEE 
	  AND		(SELECT ISNULL(SUM(OC.ConventionOperAmount),0)
				FROM dbo.Un_ConventionOper OC
				WHERE OC.ConventionID = R.iID_Convention_Source
				  AND OC.ConventionOperTypeID IN ('CBQ')) >= 0

	  AND		(SELECT ISNULL(SUM(OC.ConventionOperAmount),0)
				FROM dbo.Un_ConventionOper OC
				WHERE OC.ConventionID = R.iID_Convention_Source
				  AND OC.ConventionOperTypeID IN ('MMQ')) >= 0

and c.ConventionNo in (
'1341034',
'1341042',
'1416513',
'1573693',
'2016125')

	  -- qui n'ont pas de compte en perte
	  /*
	  AND NOT EXISTS (SELECT CO.ConventionOperTypeID,SUM(CO.ConventionOperAmount)
					  FROM Un_ConventionOper CO
					  WHERE CO.ConventionID = R.iID_Convention_Source
						AND (CHARINDEX(CO.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0)
					  GROUP BY CO.ConventionOperTypeID
					  HAVING SUM(CO.ConventionOperAmount) < 0)
		*/
		
select QteCurseur =  COUNT(*) from @tblConvRio
select * /*INTO tblNEW*/ FROM @tblConvRio	 
	 
	 --return
	 
DECLARE curRIO_Sans_IQEE CURSOR LOCAL FAST_FORWARD FOR
	  
	SELECT	 iID_Convention_Source	
			,vcConventionNoSource
			,iID_Unite_Source		
			,OperTypeID -- FT1
--			,(SELECT iConventionDestination FROM dbo.fntOPER_ValiderRetransfertRIO(iID_Convention_Source))
	FROM @tblConvRio

OPEN curRIO_Sans_IQEE
FETCH NEXT FROM curRIO_Sans_IQEE INTO	 @iID_Convention_Source
										,@vcConventionNoSource
										,@iID_Unite_Source
										,@OperTypeID -- FT1
										--,@iID_Convention_Cible -- FT2
SET @i = 0
WHILE @@FETCH_STATUS = 0
	BEGIN
	
		set @i = @i + 1
	
		--PRINT @iConnectId
		--PRINT @iID_Convention_Source
		--PRINT @iID_Unite_Source
		--PRINT @dtDateDuJour
		--PRINT @dtDateDuJour
		--PRINT @iID_Convention_Cible -- NULL -- FT2
		--PRINT @OperTypeID
		print @i
	
		SELECT @iID_Convention_Cible = iConventionDestination, @iElligible = iElligible FROM dbo.fntOPER_ValiderRetransfertRIO(@iID_Convention_Source)
		
		-- Traite uniquement les conventions qui sont elligibles au retransfert FT2
		if @iElligible = 1 
		begin
		
			-- Traitement des soldes négatifs
			exec psTEMP_GenererARIAutoSansValidation @UserID =  'DHUPPE', @vcConventionNo =@vcConventionNoSource
		
			-- Transférer les montants
			EXECUTE [dbo].[psOPER_CreerOperationRIO] @iConnectId
													,@iID_Convention_Source
													,@iID_Unite_Source
													,@dtDateDuJour
													,@dtDateDuJour
													,@iID_Convention_Cible -- NULL -- FT2
													,@OperTypeID
													,1
			insert into tbl_TEMPRetransfertRIO values (@vcConventionNoSource)
		end
												
		FETCH NEXT FROM curRIO_Sans_IQEE INTO	 @iID_Convention_Source
												,@vcConventionNoSource
												,@iID_Unite_Source
												,@OperTypeID -- FT1
												--,@iID_Convention_Cible -- FT2
	END
CLOSE curRIO_Sans_IQEE
DEALLOCATE curRIO_Sans_IQEE

SELECT * 
FROM Un_Oper
WHERE OperID > @MaxOperID

end

