/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_CommForAccounting_CrossTAB
Description         :	PROCEDURE DU RAPPORT SOMMAIRE DES COMMISSIONS POUR ÉCRITURE COMPTABLE
Valeurs de retours  :	Dataset
Note                :	UTILISE LA SP : RP_UN_CommForAccounting_TBL

				2008-12-02 	Donald Huppé	Création

-- exec RP_UN_CommForAccounting_CrossTAB 269, 316
-- exec RP_UN_CommForAccounting_CrossTAB 310, 313
****************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CommForAccounting_CrossTAB] (
	@RepTreatmentIDFrom INTEGER, -- Numéro du traitement des commissions DE
	@RepTreatmentIDTo INTEGER) -- Numéro du traitement des commissions À
AS

BEGIN

	declare 
		@i int,
		@CreatetableStr varchar(5000),
		@KindOfAmount varchar(50),
		@SQLStr varchar(5000),
		@UPDSQLStr varchar(5000),
		@RepTreatmentDate MoDate,
		@ColomnDate varchar(8)

	if exists (select name from sysobjects where name = 'TMPRepTreatmentReportCrossTab')
	begin
		drop table TMPRepTreatmentReportCrossTab
	end

	-- On met dans une table tout les champs de la table TMPRepTreatmentReport que l'on met en ligne
	-- Et l'ordre dans les lequels on voudrait les voir
	create table #KindOfAmount ([Ordre] int, [KindOfAmount] varchar(50) )
	insert into #KindOfAmount values (1,'NewAdvance')		-- Avance
	insert into #KindOfAmount values (2,'CommAndBonus')		-- ComServBoni
	insert into #KindOfAmount values (3,'Adjustment')		-- BoniConAju
	insert into #KindOfAmount values (4,'Retenu')			-- Retenu
	insert into #KindOfAmount values (5,'ChqNet')			-- Net
	insert into #KindOfAmount values (6,'Advance')			-- AvACouvrir
	insert into #KindOfAmount values (7,'TerminatedAdvance')-- AvResil
	insert into #KindOfAmount values (8,'SpecialAdvance')	-- AvSpecial
	insert into #KindOfAmount values (9,'TotalAdvance')		-- AvTotal
	insert into #KindOfAmount values (10,'CoveredAdvance')	-- AvCouv
	insert into #KindOfAmount values (11,'CommissionFee')	-- DepCom
	
	-- Mettre les valeurs de départ pour chaque période dans la table TMPRepTreatmentReport 
	DELETE FROM TMPRepTreatmentReport	
	SET @i = @RepTreatmentIDFrom
	WHILE @i <= @RepTreatmentIDTo
	BEGIN
		EXEC RP_UN_CommForAccounting_TBL 213901, @i
		SET @i = @i + 1
	END
	
	-- Début du SQL de création de la table TMPRepTreatmentReportCrossTab
	SET @CreatetableStr = 'CREATE TABLE [dbo].[TMPRepTreatmentReportCrossTab](
										[KindOfAmount] [varchar](30),
										[RepID] [dbo].[MoID],
										[RepCode] [dbo].[MoDescoption] NULL,
										[RepName] [dbo].[MoDesc] NULL,
										[BusinessStart]	[dbo].MoDateoption NULL,
										[BusinessEnd] [dbo].MoDateoption NULL,
										[TotalAmount] [dbo].[MoMoney]'

	-- Début du SQL de Update des totaux pour toutes les périodes
	SET @UPDSQLStr = 'update TMPRepTreatmentReportCrossTab set totalAmount = 0 '

	DECLARE Date_cursor CURSOR FOR

	SELECT TheDate = CONVERT(varchar(8),RepTreatmentDate,112)
	FROM Un_Reptreatment
	WHERE RepTreatmentID between @RepTreatmentIDFrom and @RepTreatmentIDTo

	OPEN Date_cursor

	FETCH NEXT FROM Date_cursor
	INTO @ColomnDate

	-- Om prépare les SQL 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- SQL de création de table
		SET @CreatetableStr = @CreatetableStr + ', [' + @ColomnDate + '] [dbo].[MoMoney] '
	
		-- SQL de update des totaux pour toutes les périodes
		SET @UPDSQLStr = @UPDSQLStr + ' + [' + @ColomnDate + ']'

		FETCH NEXT FROM Date_cursor
		INTO @ColomnDate
	END

	SET @CreatetableStr = @CreatetableStr + ' )' 

	CLOSE Date_cursor
	DEALLOCATE Date_cursor

	-- Création de la table RepTreatmentReportCrossTab et des index	
	EXEC (@CreatetableStr)
	CREATE INDEX XKindOfAmount ON TMPRepTreatmentReportCrossTab(KindOfAmount)
	CREATE INDEX XRepID ON TMPRepTreatmentReportCrossTab(RepID)

	-- Ouvrir un curseur pour tous les kindOfAmount
	DECLARE Amount_cursor CURSOR FOR
	SELECT KindOfAmount FROM #KindOfAmount
	OPEN Amount_cursor
	FETCH NEXT FROM Amount_cursor INTO @KindOfamount
	WHILE @@FETCH_STATUS = 0
	BEGIN

		-- Insérer tous les Rep pour le KindOfamount en cours de curseur
		set @SQLStr = 'insert into TMPRepTreatmentReportCrossTab (KindOfAmount,RepID) 
		select distinct ''' + @KindOfamount + ''',RepID from TMPRepTreatmentReport'

		exec (@SQLStr)

		-- Ouvrir un curseur pour tous les traitements demandés
		DECLARE Date_cursor CURSOR FOR
		SELECT TheDate = CONVERT(varchar(8),RepTreatmentDate,112)
		FROM Un_Reptreatment
		WHERE RepTreatmentID between @RepTreatmentIDFrom and @RepTreatmentIDTo

		OPEN Date_cursor

		FETCH NEXT FROM Date_cursor
		INTO @ColomnDate

		WHILE @@FETCH_STATUS = 0
		BEGIN

			-- On update les Amount du traitement en cours de curseur
			set @SQLStr = 'update RC set [' + @ColomnDate + '] = ' + @KindOfamount + ' from TMPRepTreatmentReportCrossTab RC
							join TMPRepTreatmentReport R on RC.REPID = R.REPID 
							and CONVERT(varchar(8),R.RepTreatmentDate,112) = ''' + @ColomnDate + '''' + 
							' and RC.KindOfAmount = ''' + @KindOfamount + ''''
			exec (@SQLStr)
			FETCH NEXT FROM Date_cursor
			INTO @ColomnDate
		END

		CLOSE Date_cursor
		DEALLOCATE Date_cursor

	FETCH NEXT FROM Amount_cursor
	INTO @KindOfamount

	END

	CLOSE Amount_cursor
	DEALLOCATE Amount_cursor

	-- Calculer les montant totaux (TotalAmount) pour tous les traitements
	exec (@UPDSQLStr)

	-- Aller chercher l'info sur le Rep
	UPDATE t 
	SET 
		t.repcode = r.repcode,
		t.repname = h.lastname + ' ' + h.firstname,
		t.BusinessStart = r.BusinessStart,
		t.BusinessEnd = r.BusinessEnd
	FROM TMPRepTreatmentReportCrossTab T
	JOIN un_rep r on t.repid = r.repid
	JOIN dbo.mo_human h on r.repid = h.humanid

	-- On retourne le contenu de la table
	select C.* 
	from TMPRepTreatmentReportCrossTab C
	join #KindOfAmount K on C.KindOfAMount = K.KindOfAMount
	order by K.ordre, c.repcode

END


