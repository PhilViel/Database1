/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	DL_CRQ_Company
Description         :	Procédure de suppression de compagnie.
Valeurs de retours  :	@ReturnValue :
									> 0 : La suppression a réussie.  La valeur de retour correspond au CompanyID de 
											la compagnie supprimée.
									<= 0: La suppression a échouée.
Note                :	ADX0000730	IA	2005-06-13	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE  PROCEDURE [dbo].[DL_CRQ_Company] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@CompanyID INTEGER ) -- ID de la compagnie à supprimer.
AS
BEGIN
	DECLARE
		@iResultID INTEGER,
		@LogDesc MoNoteDescOption,
		@CompanyName MoCompanyName,
		@LangID MoLang,
		@WebSite MoEmail,
		@StateTaxNumber MoDescOption,
		@CountryTaxNumber MoDescOption,
		@EndBusiness MoDateOption,
		@DepID MoID

	SET @iResultID = 1

	IF EXISTS (
		SELECT CompanyID
	   FROM Mo_Company
	   WHERE CompanyID = @CompanyID )
	BEGIN
		-- Initialisation des variables pour le log
		SET @LogDesc = ''
		SELECT
			@CompanyName = CompanyName,
			@LangID = LangID,
			@WebSite = WebSite,
			@StateTaxNumber = StateTaxNumber,
			@CountryTaxNumber = CountryTaxNumber,
			@EndBusiness = EndBusiness
		FROM Mo_Company
		WHERE CompanyID = @CompanyID

		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('MO_COMPANY', 'DEL', '', @CompanyName)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('MO_COMPANY', 'COMPANYNAME', '', @CompanyName)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('MO_COMPANY', 'LANG', '', @LangID)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('MO_COMPANY', 'WEBSITE', '', @WebSite)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('MO_COMPANY', 'STATETAXNUMBER', '', @StateTaxNumber)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('MO_COMPANY', 'COUNTRYTAXNUMBER', '', @CountryTaxNumber)
		SET @LogDesc = @LogDesc + dbo.FN_CRQ_FormatLog ('MO_COMPANY', 'ENDBUSINESS', '', CAST(@EndBusiness AS CHAR))

		DECLARE MoDepList CURSOR FOR
			SELECT
				D.DepID
			FROM Mo_Dep D
			JOIN Mo_Company C ON C.CompanyID = D.CompanyID
			WHERE C.CompanyID = @CompanyID

		OPEN MoDepList

		FETCH NEXT FROM MoDepList
		INTO
			@DepID

		WHILE @@FETCH_STATUS = 0 AND @iResultID > 0
		BEGIN
			EXECUTE @iResultID = DL_CRQ_Dep @ConnectID, @DepID

			FETCH NEXT FROM MoDepList
			INTO
				@DepID
		END
		CLOSE MoDepList
		DEALLOCATE MoDepList

		IF @iResultID > 0
		BEGIN
			DELETE
			FROM Mo_Note
			WHERE NoteID IN ( 
					SELECT NoteID
					FROM Mo_Note N
					JOIN Mo_NoteType T ON T.NoteTypeID = N.NoteTypeID
					WHERE N.NoteCodeID = @CompanyID
						AND T.NoteTypeClassName IN ('TMOCOMPANY','TMOAGENCY','TMOFIRM','TMOPOSTCOMPANY') 
					)
			IF @@ERROR <> 0
				SET @iResultID = -1
		END

		IF @iResultID > 0
		BEGIN
			DELETE
			FROM Mo_Company
			WHERE CompanyID = @CompanyID

			IF @@ERROR = 0
			BEGIN
				EXECUTE SP_IU_CRQ_Log @ConnectID, 'Mo_Company', @CompanyID, 'D', @LogDesc
				SET @iResultID = @CompanyID
			END
			ELSE
				SET @iResultID = -2
		END
	END

	RETURN @iResultID
END
