/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_RepCombo_SSRS_ByPass_Rightid
Description         :	Procédure de recherche de représentant.
Valeurs de retours  :	Dataset :
Note                :	2009-05-20	Donald Huppé	Création
						2011-03-18	Donald Huppé	Ajout de l'option @IncludeActifInactif par défaut à 0. Pour utilisation par URL par RapSommaireCommission seulement. pour l'instant.
						2017-08-30	Donald Huppé	création de SL_UN_RepCombo_SSRS_ByPass_Rightid qui ne valide pas le paramètre @Rightid
exec SL_UN_RepCombo_SSRS 'universitas\dhuppe', 171,1, 1
exec SL_UN_RepCombo_SSRS 'universitas\dhuppe', 171,0, 1
exec SL_UN_RepCombo_SSRS 'sbabeux', 171, 1,1

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepCombo_SSRS_ByPass_Rightid] (	
	@LoginNameID VARCHAR (255),  -- Identifiant unique de l'authentification windows
	@Rightid Integer, -- Identifiant du droit UniAccès exigé (ex : 171 pour Unités brutes et Nettes)
	@IncludeAll integer,   -- Option indiquant si on doit ajouter l'option "Tous les représentant" (avec RepID = 0) dans la liste. Car certain rapport n'utilise pas cette option
	@IncludeActifInactif integer = 0
	)
AS
BEGIN
	DECLARE
		@UserID INTEGER,
		@RepID INTEGER, -- Identifiant unique du représentant (0 pour tous)
		@BossID INTEGER, -- Identifiant unique du directeur (0 = pas un directeur)
		@MaxRightID INTEGER

	set @LoginNameID = substring(@LoginNameID, CHARINDEX ( '\' ,@LoginNameID , 1 ) + 1   , 99)

	-- Table des résultats
	CREATE TABLE #tResultat (Groupe INTEGER, RepID INTEGER, RepName varchar(255))

	-- Table des rep à afficher
	CREATE TABLE #tRep (RepID INTEGER)

	select @UserID = UserID from mo_user where LoginNameID =  @LoginNameID

	-- Voir s'il s'agit d'un Rep ou d'un Boss
	select @RepID = u.UserID 
	from 
		mo_user u
		JOIN dbo.mo_human h on u.userid = h.humanid
		join un_rep r on h.humanid = r.repid
	where u.userid = @UserID

	-- Voir si le user a accès au rapport via les Accès Uniaccès
	select @MaxRightID = max(rightid) from (
		SELECT 
		R.RightID
		FROM Mo_Right R
		JOIN Mo_RightType T ON (T.RightTypeID = R.RightTypeID)
		JOIN Mo_UserRight U ON (U.UserID = @UserID) AND (U.RightID = R.RightID) AND (U.Granted <> 0) 
		where r.rightid = @Rightid
		UNION 
		SELECT 
		R.RightID
		FROM Mo_Right R
		JOIN Mo_RightType T ON (T.RightTypeID = R.RightTypeID)
		JOIN Mo_UserGroupRight GR ON (GR.RightID = R.RightID) 
		JOIN Mo_UserGroupDtl D ON (D.UserGroupID = GR.UserGroupID) AND (D.UserID = @UserID)
		LEFT JOIN Mo_UserRight U ON (U.UserID = @UserID) AND (U.RightID = R.RightID) AND (U.Granted = 0)
		WHERE r.rightid = @Rightid and U.UserID IS NULL) V

	SET @MaxRightID = 1
	
	-- Si (c'est un Rep ou un Boss) ET qu'il a accès au rapport
	if isnull(@RepID,0) <> 0 and isnull(@MaxRightID,0) <> 0
	begin
		-- loader la table avec le rep ou les rep du boss
		INSERT #tRep
		EXECUTE SL_UN_BossOfRep @RepID

		insert into #tResultat
		SELECT	
			Groupe = 1,
			R.RepID,
			RepName = H.LastName + ',' + H.FirstName + CASE WHEN R.RepCode IS NULL THEN '' ELSE ' (' + R.RepCode + ')' END + CASE WHEN R.BusinessEnd IS NULL THEN '' ELSE ' (Inactif)' END
		FROM Un_Rep R
		JOIN #tRep B ON R.RepID = B.RepID
		JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	end

	-- Si (N'est PAS un Rep ou un Boss) ET (qu'il a accès au rapport)
	if isnull(@RepID,0) = 0 and isnull(@MaxRightID,0) <> 0
	begin
		-- Loader la table avec tous les rep ET L'option "Tous les représentants"
		insert into #tResultat
		SELECT	
			Groupe = 1,
			R.RepID,
			RepName = H.LastName + ',' + H.FirstName + CASE WHEN R.RepCode IS NULL THEN '' ELSE ' (' + R.RepCode + ')' END + CASE WHEN R.BusinessEnd IS NULL THEN '' ELSE ' (Inactif)' END
		FROM Un_Rep R
		JOIN dbo.Mo_Human H ON H.HumanID = R.RepID

	end

	-- Si (N'est PAS un Rep ou un Boss) ET (qu'il a accès au rapport) ET (l'option "Tous les représentant" est demandée)
	if isnull(@RepID,0) = 0 and isnull(@MaxRightID,0) <> 0 and @IncludeAll = 1
	begin
		-- Loader la table avec tous les rep ET L'option "Tous les représentants"
		insert into #tResultat values (0,0,'Tous les représentants')
	End

	-- Si (N'est PAS un Rep ou un Boss) ET (qu'il a accès au rapport) ET (l'option "RepActifInactif" est demandée)
	if isnull(@RepID,0) = 0 and isnull(@MaxRightID,0) <> 0 and @IncludeActifInactif = 1
	begin
		-- Ajouter Les options Rep actifs et inactif
		insert into #tResultat values (0,1,'Représentants actifs')
		insert into #tResultat values (0,2,'Représentants inactifs')
	End
/****************************************/
	-- si c'est un login IIS qui est utilisé par l'application, on retourne tous les rep et 0.
	-- ex : UNIVERSITAS\SRV-IIS-01$
	if @LoginNameID like '%$'
	begin

		delete from #tResultat

		insert into #tResultat
		SELECT	
			Groupe = 1,
			R.RepID,
			RepName = H.LastName + ',' + H.FirstName + CASE WHEN R.RepCode IS NULL THEN '' ELSE ' (' + R.RepCode + ')' END + CASE WHEN R.BusinessEnd IS NULL THEN '' ELSE ' (Inactif)' END
		FROM Un_Rep R
		JOIN dbo.Mo_Human H ON H.HumanID = R.RepID

		UNION

		select
			Groupe = 0,
			RepID = 0,
			RepName = 'Tous les représentants'
	end
/*****************************************/

	-- Retourner les résultats
	select * from #tResultat order by Groupe, repname

END


