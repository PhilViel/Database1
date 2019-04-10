/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	RP_RightByUserOrGroup
						utilise SP_ExportTableToExcelWithColumns pour génération du fichier Excel
Description         :	Pour le rapport des droits Du Logiciel UniAcces
Paramètres			:	
						@ListOfBankTypeCode : peut être vide,
							'item1,item2,item3,etc' = Liste de Code de banque avec ou sans %
						@ListOfBankTransit :  peut être vide,
							'item1,item2,item3,etc' = Liste de no de succursale avec ou sans %
						@ListOfTransitNo :  peut être vide,
							'item1,item2,item3,etc' = Liste de no de compte avec ou sans %
						@AccountName : peut être vide, Nom de compte avec ou sans %
						@SearchInLog : Doit-on chercher dans le log ? 1=oui, 0=non

Valeurs de retours  :	Dataset 
							
Note                :	2009-04-24	Donald Huppé	Création
					:	2009-08-11	Donald Huppé	Ajout de l'option de recherche dans le log (@SearchInLog)

-- exec GU_RP_TransitBancaire '', '','', 'TESSIER,',1
-- exec GU_RP_TransitBancaire '', '','', 'DOUCET, GUY,',1
-- exec GU_RP_TransitBancaire '00601,%00602%,00603,%00604%', '%7720386%,%00602%', ''
-- exec GU_RP_TransitBancaire '00601,%00602%,00603,%00604%', '', 'gosselin%'
-- exec GU_RP_TransitBancaire '', '', 'GOSSEL%'
-- exec GU_RP_TransitBancaire '', '386%'
-- exec GU_RP_TransitBancaire '','', '040%,234','',1
-- exec GU_RP_TransitBancaire '','', '0400135' , ' ', 1

****************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_TransitBancaire] (

	@ListOfBankTypeCode varchar(255),	-- Code de la banque
	@ListOfBankTransit varchar(1000),	-- No de succursale
	@ListOfTransitNo varchar(1000),		-- No de compte
	@AccountName varchar(255),			-- Nom du compte
	@SearchInLog 	bit					-- Doit-on chercher dans le log ? 1=oui, 0=non

	)
AS

BEGIN

declare 
	@ListOfItem varchar(1000),
	@item varchar(1000),
	@WhereBankTransit varchar(1000),
	@WhereTransitNo varchar(1000),
	@WhereBankCode varchar(1000),
	@ItemPos int,
	@ItemPosPrec int,
	@NbOfItem int,
	@Sql varchar(4000)

	set @ItemPos = 1
	set @ItemPosPrec = 1
	set @NbOfItem = 0
	set @WhereBankCode = ''
	set @ListOfItem = @ListOfBankTypeCode
	while @ItemPos > 0  AND LEN(ISNULL(@ListOfItem,'')) > 0
	begin
		if @ListOfItem not like '%,' set @ListOfItem = @ListOfItem + ','
		set @NbOfItem = @NbOfItem + 1
		set @ItemPos = CHARINDEX( ',', @ListOfItem, @ItemPosPrec)
		set @item = SUBSTRING ( @ListOfItem ,@ItemPosPrec , @ItemPos  - @ItemPosPrec )
		set @ItemPosPrec = @ItemPos + 1
		set @ItemPos = CHARINDEX ( ',' , @ListOfItem , @ItemPos + 1 )
		set @WhereBankCode = @WhereBankCode + case when @NbOfItem > 1 then ' or ' else '(' end + ' BankTypeCode' + case when CHARINDEX ( '%' ,@item , 1 ) >= 1 then ' like ' else ' = ' end + '''' + ltrim(rtrim(@item)) + ''''
	end
	if len(ltrim(rtrim(@WhereBankCode))) > 0 set @WhereBankCode = @WhereBankCode + ')'

	set @ItemPos = 1
	set @ItemPosPrec = 1
	set @NbOfItem = 0
	set @WhereBankTransit = ''
	set @ListOfItem = @ListOfBankTransit
	while @ItemPos > 0  AND LEN(ISNULL(@ListOfItem,'')) > 0
	begin
		if @ListOfItem not like '%,' set @ListOfItem = @ListOfItem + ','
		set @NbOfItem = @NbOfItem + 1
		set @ItemPos = CHARINDEX( ',', @ListOfItem, @ItemPosPrec)
		set @item = SUBSTRING ( @ListOfItem ,@ItemPosPrec , @ItemPos  - @ItemPosPrec )
		set @ItemPosPrec = @ItemPos + 1
		set @ItemPos = CHARINDEX ( ',' , @ListOfItem , @ItemPos + 1 )
		set @WhereBankTransit = @WhereBankTransit + case when @NbOfItem > 1 then ' or ' else '(' end + ' BankTransit' + case when CHARINDEX ( '%' ,@item , 1 ) >= 1 then ' like ' else ' = ' end + '''' + ltrim(rtrim(@item)) + ''''
	end
	if len(ltrim(rtrim(@WhereBankTransit))) > 0 set @WhereBankTransit = @WhereBankTransit + ')'

	set @ItemPos = 1
	set @ItemPosPrec = 1
	set @NbOfItem = 0
	set @WhereTransitNo = ''
	set @ListOfItem = @ListOfTransitNo
	while @ItemPos > 0 AND LEN(ISNULL(@ListOfItem,'')) > 0
	begin
		if @ListOfItem not like '%,' set @ListOfItem = @ListOfItem + ','
		set @NbOfItem = @NbOfItem + 1
		set @ItemPos = CHARINDEX( ',', @ListOfItem, @ItemPosPrec)
		set @item = SUBSTRING ( @ListOfItem ,@ItemPosPrec , @ItemPos  - @ItemPosPrec )
		set @ItemPosPrec = @ItemPos + 1
		set @ItemPos = CHARINDEX ( ',' , @ListOfItem , @ItemPos + 1 )
		set @WhereTransitNo = @WhereTransitNo + case when @NbOfItem > 1 then ' or ' else '(' end + ' TransitNo' + case when CHARINDEX ( '%' ,@item , 1 ) >= 1 then ' like ' else ' = ' end + '''' + ltrim(rtrim(@item)) + ''''
	end
	if len(ltrim(rtrim(@WhereTransitNo))) > 0 set @WhereTransitNo = @WhereTransitNo + ')'

	set @Sql = ''
	set @Sql = @Sql + '
	SELECT 
		DISTINCT 
		ActualValue = 1,
		BA.BankTransit,
		CA.TransitNo,
		SName = h.lastname + '' '' + h.firstname, 
		C.conventionno,
		BT.BankTypeName, 
		BankTypeCode, 
		CA.AccountName
	FROM 
		Un_ConventionAccount CA
		JOIN Mo_Bank BA ON BA.BankID = CA.BankID
		JOIN dbo.Un_Convention C ON C.ConventionID = CA.ConventionID
		JOIN dbo.mo_human h on c.subscriberID = h.humanID
		LEFT JOIN Mo_BankType BT ON BT.BankTypeID = BA.BankTypeID
	WHERE ' +	case when len(@WhereBankCode+@WhereBankTransit+@WhereTransitNo+@AccountName) = 0 THEN '1=2' ELSE '1=1' END 

	set @Sql = @Sql + case when len(@WhereBankCode) > 0 then 'AND ' + @WhereBankCode else '' end
	set @Sql = @Sql + case when len(@WhereBankTransit) > 0 then 'AND ' + @WhereBankTransit else '' end
	set @Sql = @Sql + case when len(@WhereTransitNo) > 0 then 'AND ' + @WhereTransitNo else '' end
	set @Sql = @Sql + case when len(@AccountName) > 0 THEN ' AND CA.AccountName like ''%' + @AccountName + '%'''  else '' end

	-- Si on demande de chercher dans le log pour un TransitNo
	if @SearchInLog = 1 and LEN(ISNULL(@WhereTransitNo,'')) > 0
		begin

		set @Sql = @Sql + ' 
		UNION 
		select * 
		from (

			SELECT 
				DISTINCT 
				ActualValue = 0,
				BankTransit = '' '',
				TransitNo = REPLACE(substring(logtext,    CHARINDEX(''TransitNo'',logtext)+10,    CHARINDEX(CHAR(30),logtext, CHARINDEX(''TransitNo'',logtext)+10) - CHARINDEX(CHAR(30),logtext, CHARINDEX(''TransitNo'',logtext)+9)),CHAR(30),''''),
				SName = h.lastname + '' '' + h.firstname, 
				C.conventionno,
				BankTypeName = '' '', 
				BankTypeCode = '' '', 
				AccountName = '' ''
			FROM 
				Un_Convention C
				JOIN dbo.mo_human h on c.subscriberID = h.humanID
				join crq_log L on L.LogCodeID = C.ConventionID 
						and L.LogActionID = 2
						and L.LogTableName = ''Un_Convention'' 
						and L.LogDesc like ''%Compte bancaire de convention%'' 
						and L.LogText like ''%TransitNo%''
				) V
			WHERE ' + @WhereTransitNo

		end

	-- Si on demande de chercher dans le log pour un Nom de compte
	if @SearchInLog = 1 and len(@AccountName) > 0
		begin

		set @Sql = @Sql + ' 
			UNION 
			SELECT 
				DISTINCT 
				ActualValue = 0,
				BankTransit = '' '',
				TransitNo = '' '',
				SName = h.lastname + '' '' + h.firstname, 
				C.conventionno,
				BankTypeName = '' '', 
				BankTypeCode = '' '', 
				AccountName = REPLACE(substring(logtext,    CHARINDEX(''AccountName'',logtext)+12,    CHARINDEX(CHAR(30),logtext, CHARINDEX(''AccountName'',logtext)+12) - CHARINDEX(CHAR(30),logtext, CHARINDEX(''AccountName'',logtext)+10)),char(30),'''')
			FROM 
				Un_Convention C
				JOIN dbo.mo_human h on c.subscriberID = h.humanID
				join crq_log L on L.LogCodeID = C.ConventionID 
						and L.LogActionID = 2
						and L.LogTableName = ''Un_Convention'' 
						and L.LogDesc like ''%Compte bancaire de convention%'' 
						and L.LogText like ''%AccountName%''

			WHERE REPLACE(substring(logtext,    CHARINDEX(''AccountName'',logtext)+12,    CHARINDEX(CHAR(30),logtext, CHARINDEX(''AccountName'',logtext)+12) - CHARINDEX(CHAR(30),logtext, CHARINDEX(''AccountName'',logtext)+10)),char(30),'''') like ''%' + @AccountName + '%'''

		end

set @Sql = @Sql + ' 
	 order by 
		BankTypeCode,
		BankTransit,
		TransitNo,
		AccountName,
		h.lastname + '' '' + h.firstname,
		conventionno
	'

exec (@Sql)

end


