/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 : SP_SL_CRQ_Journalisation (basé sur dbo.SP_SL_CRQ_LogOfObject)
Description         : Journal des modifications d'un objet.
Valeurs de retours  : >0  : Tout à fonctionné
                      <=0 : Erreur SQL 
Note                : ADX0000591 IA 2004-11-22	Bruno Lapointe		 Création
									2008-12-19	Pierre-Luc Simard	 Supprimer les blobs temporaires
									2014-10-27	Pierre-Luc Simard	 Ajouts des changements de représentant au niveua des unités
									2015-02-02	Donald Huppé		 Si CRQ_Log.loginName est non NULL, alors le mettre dans UserName, au lieu de l'humain du connectID
									2015-07-17	Steeve Picard		 Cloner du schema «dbo» dans celui de «ProAcces» pour les groupe d'unité
									2015-08-26	Steeve Picard		 Fixer la largeur du champ «Value» de la table «@TB_LogLine», passant de 100 à 200
									2015-09-30	Steeve Picard		 Ajout du paramèetre @NasVisible à FALSE par défaut qui offusquera les NAS
                                    2016-08-03  Steeve Picard        Correction pour tenir compte des fusions (LogAction = 'F')
									2018-03-13  Jean-Philippe Simard Ajout des ID de bénéficiaire et des ID de souscripteur dans les logs
	exec ProAcces.SP_SL_CRQ_Journalisation 'Un_Convention', 454111
*********************************************************************************************************************/
CREATE PROCEDURE [ProAcces].[SP_SL_CRQ_Journalisation] (
	@LogTableName	VARCHAR(75),	-- Type d'objet (Un_Convention, Un_Beneficiairy, Un_Subscriber, CRQ_User)
	@LogCodeID		INTEGER,		-- ID de l'objet
	@NasVisible		BIT = 0
) AS
BEGIN
	SET NoCount ON

	DECLARE @CrLf varchar(2) = char(13) + char(10),
			@RS varchar(2) = char(30)

	DECLARE @TB_Log TABLE (
				LogID int,
				LogTime datetime,
				UserName varchar(75),
				LogTableName varchar(50),
				LogAction char(1),
				LogSubAction varchar(50) DEFAULT(''),
				LogText varchar(max)
			)

	INSERT INTO @TB_Log (LogID, LogTime, UserName, LogTableName, LogAction, LogText)
		SELECT	LogID, LogTime, LoginName, @LogTableName,
				LogAction = (SELECT LogActionShortName FROM CRQ_LogAction WHERE LogActionID = L.LogActionID), 
				LogText = Cast(LogText as varchar(max))
			FROM dbo.CRQ_Log L
			WHERE LogTableName = @LogTableName AND LogCodeID = @LogCodeID And Len(Cast(LogText as varchar(max))) > 0
			  AND not (LogTableName = 'Un_Subscriber' And LogDesc Like 'Profil souscripteur :%')

	IF @LogTableName = 'Un_Convention' BEGIN
		; WITH 
			CTE_Unit As (Select UnitID, InForceDate, UnitQty From dbo.UN_Unit Where ConventionID = @LogCodeID),
			CTE_Log as (Select LogID, LogTime, LoginName, LogTableName, LogActionID, InForceDate, UnitQty,
			                   LogText = CAST(LogText AS VARCHAR(8000))
			              From Mo_Log L JOIN CTE_Unit U ON L.LogCodeID = U.UnitID 
						 Where LogTableName = 'Un_Unit')
		INSERT INTO @TB_Log (LogID, LogTime, UserName, LogTableName, LogAction, LogSubAction, LogText)
			SELECT	LogID, LogTime, LoginName, LogTableName, LogActionID,
					' G.U.: ' + CONVERT(varchar(10), InForceDate, 120) + ' (' + LTrim(Str(UnitQty, 10, 3)) + ')',
					LogText = Replace(Replace(Replace(LogText, ': ', @RS), ' -> ', @RS), '', @RS) 
				FROM CTE_Log
				WHERE Len(LogText) > 0
	END

--IF dbo.FN_IsDebug() <> 0
--	SELECT * FROM @TB_Log order by LogTime desc

	DECLARE @TB_LogDetails TABLE (
				RowID int,
				LineValue varchar(1000)
			)

	DECLARE @TB_LogLine TABLE (
				RowNo int,
				Value varchar(200)
			)

	DECLARE @LogID int = 0,
			@LogText varchar(max),
			@RowID int,
			@RowNo int,
			@RowValue varchar(1000),
			@IsNAS bit,
			@Value varchar(1000),
			@Action varchar(2),
			@TableName varchar(50),
			@IsID bit,
			@ColumnDesc varchar(100),
			@ColumnOldValue varchar(100),
			@ColumnNewValue varchar(100)

	WHILE EXISTS(Select Top 1 * From @TB_Log Where LogID > @LogID) BEGIN

		SELECT @LogID = Min(LogID) FROM @TB_Log WHERE LogID > @LogID

		SELECT @LogText = LogText,
			   @TableName = @LogTableName,
			   @Action = LogAction
		  FROM @TB_Log 
		 WHERE LogID = @LogID
		--PRINT @LogText

		DELETE FROM @TB_LogDetails
		INSERT INTO @TB_LogDetails (RowID, LineValue)
			SELECT rowID, strField
			  FROM ProAcces.fn_SplitIntoTable(@LogText, @CrLf)
			 WHERE Len(RTrim(Replace(IsNull(strField, ''), @RS, ''))) > 0

--IF dbo.FN_IsDebug() <> 0
--    SELECT * FROM @TB_LogDetails

		SET @LogText = ''
		SET @RowID = 0
		WHILE EXISTS(Select Top 1 * From @TB_LogDetails Where RowID > @RowID) BEGIN
			SELECT @RowID = Min(RowID) FROM @TB_LogDetails WHERE RowID > @RowID

			SELECT @RowValue = LineValue
			  FROM @TB_LogDetails 
			 WHERE RowID = @RowID
            --PRINT @RowValue

			DELETE FROM @TB_LogLine
			INSERT INTO @TB_LogLine (RowNo, Value)
				SELECT rowID, strField
				  FROM ProAcces.fn_SplitIntoTable(@RowValue, @RS)
			--SELECT * FROM @TB_LogLine

--IF dbo.FN_IsDebug() <> 0
--    SELECT * FROM @TB_LogLine

			-- Regarde s'il y a une description usager du nom de colonne.
			SELECT @ColumnDesc = IsNull((Select ColumnDesc From CRQ_ColumnDesc 
			                         Where TableName = @TableName and ColumnName = L.Value and LangID = 'FRA' --@LangID
					  		     ), L.Value),
				   @IsNAS = CASE WHEN L.Value = 'SocialNumber' THEN 1
								 WHEN L.Value = 'vcPCGSIN' THEN 1 
								 ELSE 0 
				            END,
					@IsID = CASE WHEN L.Value = 'BeneficiaryID' THEN 1
								 WHEN L.Value = 'SubscriberID' THEN 1 
											ELSE 0 
									END
			  FROM @TB_LogLine L
			 WHERE RowNo = 1

			IF @IsNAS <> 0 
				UPDATE @TB_LogLine
				   SET Value = CASE WHEN @NasVisible = 1 THEN SubString(Value, 1, 3) + ' ' +  SubString(Value, 4, 3) + ' ' + SubString(Value, 7, 3)
									ELSE SubString(Value, 1, 1) + '** *** ' + SubString(Value, 7, 3)
							   END
			     WHERE RowNo > 1

			SET @RowNo = 1
			WHILE EXISTS(Select Top 1 * From @TB_LogLine Where RowNo > @RowNo) BEGIN
				SELECT @RowNo = Min(RowNo) From @TB_LogLine Where RowNo > @RowNo
				SELECT @Value = Value From @TB_LogLine Where RowNo = @RowNo
 
				IF @Value Like '(%)'
					SET @Value = SubString(@Value, 2, Len(@Value) - 2)

				IF @Action IN ('U', 'F') BEGIN
					IF EXISTS(Select Top 1 * From @TB_LogLine Where RowNo > @RowNo) BEGIN
						SET @ColumnOldValue = @Value
						SELECT @RowNo = Min(RowNo) From @TB_LogLine Where RowNo > @RowNo
						SELECT @Value = Replace(Replace(Value, SubString(@CrLf,1,1), ''), SubString(@CrLf,2,1), '') From @TB_LogLine Where RowNo = @RowNo
						IF @Value Like '(%)' BEGIN
							SET @Value = SubString(@Value, 2, Len(@Value) - 2)
							--select @Value
						END
						SET @ColumnNewValue = @Value
					END
				END
			END

			IF @IsID <> 0 BEGIN
				DECLARE @ValueID varchar (10) = (Select Top 1 Value From @TB_LogLine Where RowNo = 2);
				DECLARE @NewID varchar (10) = (Select Top 1 Value From @TB_LogLine Where RowNo = 3);

				IF @ValueID IS NOT NULL BEGIN
					SET @ColumnOldValue = @ColumnOldValue + ' (' +  @ValueID + ')'
					SET @Value = @Value + ' (' +  @ValueID + ')'
				END

				IF @NewID IS NOT NULL BEGIN
					SET @ColumnNewValue = @ColumnNewValue + ' (' +  @NewID + ')'
				END
			END

			SET @LogText = @ColumnDesc + char(9) + @Value
			UPDATE @TB_LogDetails
			   SET LineValue = @ColumnDesc + char(9) + 
								CASE WHEN @Action IN('U','F') THEN @ColumnOldValue + char(9) + @ColumnNewValue
											 ELSE @Value
								END
			 WHERE RowID = @RowID
		END

		SET @LogText = ''
		SET @RowID = 0
		WHILE EXISTS(Select Top 1 * From @TB_LogDetails Where RowID > @RowID) BEGIN
			SELECT @RowID = Min(RowID) From @TB_LogDetails Where RowID > @RowID

			SELECT @LogText = @LogText + CASE WHEN @LogText = '' THEN '' ELSE @CrLf END + LineValue
			  FROM @TB_LogDetails
			 WHERE RowId = @RowID
		END
		UPDATE @TB_Log
		   SET logText = @LogText
		 WHERE logID = @LogId
	END

	-- Fait la sélection final des enregistrements nécessaire au journal des modifications
	SELECT
		LogID, -- ID du log
		LogTime, -- Date et l’heure à laquelle l’usager a sauvegardé la modification.
		UserName, -- Nom de l'usager
		LogAction,
		LogSubAction,
		LogText = Replace(LogText, char(30), char(9))
	FROM @TB_Log
	ORDER BY LogTime DESC, LogID DESC

	RETURN 0
END