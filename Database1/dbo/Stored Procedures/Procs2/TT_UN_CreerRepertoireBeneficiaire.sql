/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	TT_UN_CreerRepertoireBeneficiaire 
Description         :	Procédure pour créer les répertoires des Beneficiaires dans le plan de Classification 
Valeurs de retours  :	 
Note                :	2011-02-16	Donald Huppé			Créaton
						2011-05-30	Donald Huppé			GLPI 5588 : les dossiers des bénéficiaires sont dorénavant créés suite à l’activation des prélèvements (activer le groupe d’unité).
						2012-09-06	Donald Huppé			Gestion des / et \ dans les nom et prenom
						2013-01-30	Donald Huppé			glpi 9029 : le dossier du nouveau bénéficiaire suite à un changement de bénéficiaire n'était pas créé
																		ici : NewhumanId = convert(int,replace(SUBSTRING(L.LogText, 21, 7),CHAR(30),'')), je mettais 20 au lieu de 21
						2014-02-17	Pierre-Luc Simard	Création du dossier PORTAIL
exec TT_UN_CreerRepertoireBeneficiaire '2011-05-30', '2011-05-30'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CreerRepertoireBeneficiaire] 
	(
	@DateFrom datetime, -- Date limite inférieure inscrite dans le numéro de convention
	@DateTo datetime	-- Date limite supérieure inscrite dans le numéro de convention
	)

AS
BEGIN

set Nocount on

declare @FNom varchar(255)
declare @Repertoire varchar(255)
declare @cmd varchar(3000)
declare @StrDateFrom varchar(8)
declare @StrDateTo varchar(8)

	set @StrDateFrom = convert(varchar(8),@DateFrom,112)
	set @StrDateTo = convert(varchar(8),@DateTo,112)

	CREATE TABLE #tHuman (
			FPrenom varchar(1),
			Repertoire VARCHAR (500))

	insert into #tHuman

	-- Les nouvelles conventions
	select distinct
		FPrenom = dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(h.lastname)),1,1)),
		Repertoire = replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(h.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(h.firstname)),' ','_') + '_' + cast(h.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Beneficiary b on c.beneficiaryid = b.beneficiaryid
	JOIN dbo.mo_human h on b.beneficiaryid = h.humanid
	JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
	join Mo_Connect cn ON u.ActivationConnectID = cn.ConnectID
	where  LEFT(CONVERT(VARCHAR, cn.ConnectStart, 120), 10) BETWEEN LEFT(CONVERT(VARCHAR, @DateFrom, 120), 10) AND LEFT(CONVERT(VARCHAR, @DateTo, 120), 10)
		OR LEFT(CONVERT(VARCHAR, cn.ConnectEnd, 120), 10) BETWEEN LEFT(CONVERT(VARCHAR, @DateFrom, 120), 10) AND LEFT(CONVERT(VARCHAR, @DateTo, 120), 10)
	--substring(c.conventionno,3,8) between @StrDateFrom and @StrDateTo

	UNION

	-- Les conventions modifiés au niveau du bénéficiaire
	select distinct
		FPrenom = dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(h.lastname)),1,1)),
		Repertoire = replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(h.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(h.firstname)),' ','_') + '_' + cast(h.humanid as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','')
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Beneficiary b on c.beneficiaryid = b.beneficiaryid
	JOIN dbo.mo_human h on b.beneficiaryid = h.humanid
	where h.humanid in (
		SELECT 
			NewhumanId = convert(int,replace(SUBSTRING(L.LogText, 21, 7),CHAR(30),''))
		FROM 
			CRQ_Log L
		WHERE 
			L.LogTableName = 'Un_Convention' 
			AND L.LogActionID = 2
			AND L.LogText LIKE 'beneficiaryID%'
			and convert(varchar(10),l.logtime,127) between @DateFrom and @DateTo
		)

	DECLARE MyCursor CURSOR FOR

		select FPrenom,Repertoire from #tHuman

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @FNom,@Repertoire

	WHILE @@FETCH_STATUS = 0
	BEGIN
 
		--print @Repertoire
		SET @cmd = 'mkdir \\gestas2\\PlanDeClassification\\8_SERVICES_A_LA_CLIENTELE\\802_GESTION_DES_CONTRATS\\802-400_BENEFICIAIRE\\' + @FNom + '\\' + @Repertoire + '\\PORTAIL' 
		EXEC XP_CMDSHELL @cmd

		FETCH NEXT FROM MyCursor INTO @FNom,@Repertoire

	END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

	drop table #tHuman

end


