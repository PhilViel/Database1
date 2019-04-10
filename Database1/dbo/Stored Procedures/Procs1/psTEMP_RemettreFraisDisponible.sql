/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psTEMP_RemettreFraisDisponible
Nom du service		: Procedure pour remettre les frais disponibles dans une convention suite à son expiration
But 				: 
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

		exec psTEMP_RemettreFraisDisponible
			@vcUserID = 'DHUPPE', 
			@ConventionNo = 'x-20131211008', --'X-20120319049',
			@DemandeDeProceder  = 0

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2018-08-30		Donald Huppé						Création du service		
		2018-09-06		Donald Huppé						Ajout d'utilisateurs ayant les droits
		2018-09-14		Donald Huppé						Ajout d'utilisateurs ayant les droits
		2018-09-17		Donald Huppé						Nouvelle validation en cas de solde de frais dispo négatif
		2018-09-18		Donald Huppé						Correction 
		2018-09-19		Donald Huppé						Gestion par groupe d'unité
		2018-09-27		Donald Huppé						correction pour le message indiquant : AUCUN FRAIS EXPIRÉS ...
															Ajout de 2 accès
		2018-10-24		Donald Huppé						jira ti-14509 : ajout de jnorman et mchaudey
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_RemettreFraisDisponible] 
(
	@vcUserID varchar(255),
	@ConventionNo VARCHAR(15),
	@DemandeDeProceder  bit = 0
)
AS
BEGIN

	DECLARE	
		@Proceder INT = 1
		,@cMessage varchar(500)

	CREATE TABLE #FraisDispo (
			Souscripteur VARCHAR(250),
			SubscriberID INT,
			BeneficiaryID INT,
			AttentionTRI INT,
			ConventionNo VARCHAR(50), 
			UnitID INT,
			InForceDate DATE,
			SoldeUniteDispo FLOAT,
			SoldeFraisDispo MONEY,

			DernierUniteExpire FLOAT, 
			SoldeUniteExpire FLOAT,  
			DernierFraisExpire MONEY, 
			SoldeFraisExpire MONEY,

			DernierOperIDExpire INT
			)

	set @cMessage = ''
	set @Proceder = 1


	if not exists (select 1 from sysobjects where Name = 'tblTEMP_RemettreFraisDisponible')
		begin
		create table tblTEMP_RemettreFraisDisponible (conventionno varchar(20), UserID varchar(255)) --drop table tblTEMP_TIOIQEE
		end

	-- On laisse un trace dans une table lors d'une demande demander de créer un RIO 
	IF 	@DemandeDeProceder = 0
		begin
		delete from tblTEMP_RemettreFraisDisponible 
		insert into tblTEMP_RemettreFraisDisponible VALUES (@ConventionNo, @vcUserID)
		end


	-- vérification que l'usager à le droit
	if @vcUserID not like '%dhuppe%'

		and @vcUserID not like '%anadeau%'
		and @vcUserID not like '%casamson%'
		and @vcUserID not like '%apoirier%'
		and @vcUserID not like '%ggrondin%'
		and @vcUserID not like '%kdubuc%'
		--and @vcUserID not like '%mcadorette%'
		and @vcUserID not like '%medurou%'
		and @vcUserID not like '%nlafond%'
		
		and @vcUserID not like '%vlapointe%'
		and @vcUserID not like '%fmenard%'

		--and @vcUserID not like '%cbourget%'
		--and @vcUserID not like '%jcloutier%'
		and @vcUserID not like '%ktardif%'
		and @vcUserID not like '%mviens%'
		
		and @vcUserID not like '%ebeaulieu%'
		and @vcUserID not like '%mchaudey%'

		and @vcUserID not like '%strichot%'

  --      and @vcUserID not like '%cheon%'

		and @vcUserID not like '%nbabin%'
		and @vcUserID not like '%gdumont%'
		and @vcUserID not like '%ktremblay%'
		--and @vcUserID not like '%mderoo%'
		--and @vcUserID not like '%mocliche%'
		--and @vcUserID not like '%mperron%'
		--and @vcUserID not like '%nfortin%'
		
		--and @vcUserID not like '%atremblay%'
		--and @vcUserID not like '%cpesant%'
		--and @vcUserID not like '%bvigneault%'
		and @vcUserID not like '%mlarrivee%'
		and @vcUserID not like '%nababin%'
		--and @vcUserID not like '%chroy%'
		
		

		and @vcUserID not like '%mgobeil%'
		--and @vcUserID not like '%elandry%'
		and @vcUserID not like '%jnorman%'
		--and @vcUserID not like '%amelay%'
		and @vcUserID not like '%mchaudey%'
	

		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">Usager non autorisé : ' + @vcUserID + '.    --> Voyez votre superviseur(e).</font>'
		set @Proceder = 0
		--goto abort
		end		

	--set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">TEST</font>'
	
	if @DemandeDeProceder = 1 and not exists(SELECT 1 from tblTEMP_RemettreFraisDisponible where conventionno = @ConventionNo)
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">Attention. Demandez d''abord le rapport sans demander de procéder !</font>'
		set @Proceder = 0
		--goto abort
		end


	INSERT INTO #FraisDispo
	SELECT 
		Souscripteur = HS.FirstName + ' ' + HS.LastName,
		SubscriberID = C.SubscriberID,
		BeneficiaryID = C.BeneficiaryID,
		AttentionTRI = case when tri.iID_Convention_Source is not null then 1 else 0 end,
		C.ConventionNo, 
		U.UnitID,
		U.InForceDate,
		SoldeUniteDispo = ISNULL(SR.UnitQtyRes,0) - ISNULL(SU.UnitQtyUse,0),
		SoldeFraisDispo = ISNULL(FD.AvailableFeeAmount, 0),

		DernierUniteExpire = ISNULL(DernierUniteExpire,0), 
		SoldeUniteExpire = ISNULL(SoldeUniteExpire,0),  
		DernierFraisExpire = ISNULL(DernierFraisExpire,0), 
		SoldeFraisExpire = ISNULL(SoldeFraisExpire,0),

		DernierOperIDExpire = ISNULL(DernierOperIDExpire,0)

	FROM 
		Un_Convention C
		JOIN Un_Unit U on U.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		LEFT JOIN ( 
	
				-- UNITÉS RÉSILIÉES

				SELECT 
					C.ConventionID, 
					UR.UnitID,
					UnitQtyRes = SUM(UR.UnitQty)
				FROM Un_UnitReduction UR
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				WHERE C.ConventionNo = @ConventionNo
				GROUP BY C.ConventionID,UR.UnitID
				) SR ON SR.UnitID = U.UnitID--SR.ConventionID = C.ConventionID
		LEFT JOIN ( 
				-- UNITÉS UTILISÉES
					-- Les untiés résiliées qui sont utilisé dans un autre groupe d'unité sont dans Un_AvailableFeeUse.fUnitQtyUse
					-- Lors de l'expiration (4 ans) des frais dispo, les unité dispo sont inscrite comme étant utilisées dans Un_AvailableFeeUse.fUnitQtyUse
				SELECT 
					C.ConventionID, 
					U.UnitID,
					UnitQtyUse = SUM(A.fUnitQtyUse)
				FROM Un_UnitReduction UR
				JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
				JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID			
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				WHERE C.ConventionNo = @ConventionNo
				GROUP BY C.ConventionID,U.UnitID
				) SU ON SU.UnitID = U.UnitID--SU.ConventionID = C.ConventionID

		LEFT JOIN (
				-- FRAIS DISPONIBLE

				-- lors de la résil :					il y a un Oper TFR qui AJOUTE un montant de frais dispo (FDI) POSITIF (LES FRAIS DEVIENNENT DISPO)
				-- apres 4 ans lors de l'expiration :	il y a un Oper TFR qui RETIRE un montant de frais dispo (FDI) NEGATIF (LES FRAIS NE SONT PLUS DISPO)

				SELECT
					CO.ConventionID,
					UnitID = ISNULL(UR.UnitID,CT.UnitID),
					AvailableFeeAmount =SUM( CO.ConventionOperAmount)
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN Un_Oper o on co.OperID = o.OperID

				-- Le UnitID lors de la résil,
				LEFT JOIN Un_Cotisation CT ON CT.OperID = O.OperID

				-- Le UnitID lors de l'expiration
				LEFT JOIN Un_AvailableFeeUse af ON af.operid = o.operid
				LEFT JOIN Un_UnitReduction UR ON UR.UnitReductionID = AF.UnitReductionID
				
				WHERE c.ConventionNo = @ConventionNo
					AND CO.ConventionOperTypeID = 'FDI' --Frais disponible
					AND (CT.UnitID IS NOT NULL OR UR.UnitID IS NOT NULL)
				GROUP BY CO.ConventionID,ISNULL(UR.UnitID,CT.UnitID)
					)FD ON FD.UnitID = U.UnitID
		LEFT JOIN (
			SELECT DISTINCT r.iID_Convention_Source
			from tblOPER_OperationsRIO r
			where r.OperTypeID = 'TRI'
			) tri on tri.iID_Convention_Source = c.ConventionID

		LEFT JOIN	(
			SELECT 
				CO.CONVENTIONID,
				UR.UnitID,
				DernierOperIDExpire = OA.OperID, 
				DernierUniteExpire = af.fUnitQtyUse, 
				S1.SoldeUniteExpire,  
				DernierFraisExpire = OA.OtherAccountOperAmount, 
				S1.SoldeFraisExpire
			FROM Un_Oper O
			JOIN Un_ConventionOper co on co.operid = o.operid
			JOIN Un_AvailableFeeUse af ON af.operid = o.operid
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = AF.UnitReductionID
			JOIN Un_OtherAccountOper OA ON OA.OperID = O.OperID
			JOIN (
				select	
					C.ConventionNo,
					UR.UnitID,
					MAX_OperID = MAX(o.OperID),
					SoldeUniteExpire = SUM(AF.fUnitQtyUse),
					SoldeFraisExpire = SUM(oa.OtherAccountOperAmount)
				FROM Un_Oper o
				JOIN Un_ConventionOper co ON co.operid = o.operid
				JOIN Un_AvailableFeeUse af ON af.operid = o.operid
				JOIN Un_UnitReduction UR ON UR.UnitReductionID = AF.UnitReductionID
				JOIN Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN Un_OtherAccountOper oa ON oa.OperID = o.OperID
				WHERE  C.ConventionNo = @ConventionNo
				GROUP BY C.ConventionNo, UR.UnitID	
				) S1 ON S1.MAX_OperID = O.OperID AND S1.UnitID = UR.UnitID
			)SoldeExpir on SoldeExpir.UnitID = U.UnitID

	WHERE c.ConventionNo = @ConventionNo


	--SELECT * FROM #FraisDispo

	--RETURN

	if NOT EXISTS (select 1 from #FraisDispo)	
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">Convention inexistante.</font>'
		set @Proceder = 0
		END

	if EXISTS (select 1 from #FraisDispo where AttentionTRI = 1)	
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">Un TRI a eu lieu dans cette convention. CRÉEZ UN JIRA POUR LES TI pour plus d''analyse sur ce cas.</font>'
		set @Proceder = 0
		END


	IF @DemandeDeProceder = 0
	 AND EXISTS (SELECT 1 FROM #FraisDispo WHERE	SoldeUniteDispo > 0 AND SoldeFraisDispo > 0 )	
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  'DES FRAIS SONT DÉJÀ DISPONIBLES.'
		--set @Proceder = 0
		END

	IF EXISTS (
		SELECT
			1
		FROM Un_ConventionOper CO
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		JOIN Un_Oper o on co.OperID = o.OperID

		-- Le UnitID lors de la résil
		LEFT JOIN Un_Cotisation CT ON CT.OperID = O.OperID

		-- Le UnitID lors de l'expiration
		LEFT JOIN Un_AvailableFeeUse af ON af.operid = o.operid
		LEFT JOIN Un_UnitReduction UR ON UR.UnitReductionID = AF.UnitReductionID
				
		WHERE c.ConventionNo = @ConventionNo
			AND CO.ConventionOperTypeID = 'FDI' --Frais disponible

			--- Clause louche qui ne devrait pas arriver
			AND (CT.UnitID IS NULL AND UR.UnitID IS NULL)

		)
		BEGIN
		-- Cas où aucun unitID ne peut être associé au FDI
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">Erreur 69. Veuillez transférer ce cas au TI.</font>'
		set @Proceder = 0
		END


	IF EXISTS (SELECT 1 FROM #FraisDispo HAVING SUM(SoldeUniteExpire) = 0 OR SUM(SoldeFraisExpire) = 0 /*WHERE	SoldeUniteExpire = 0 OR SoldeFraisExpire = 0*/ )	
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">AUCUN FRAIS EXPIRÉS ne peut être remis disponible.</font>'
		set @Proceder = 0
		END

	IF EXISTS (SELECT 1 FROM #FraisDispo WHERE	SoldeUniteDispo < 0 OR SoldeFraisDispo < -0.05 )	
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">Solde de frais disponible négatif. C''est louche. Transférez ce cas au TI avec un JIRA.</font>'
		set @Proceder = 0
		END

	IF EXISTS (SELECT 1 FROM #FraisDispo WHERE (DernierUniteExpire <> SoldeUniteExpire OR DernierFraisExpire <> SoldeFraisExpire) AND SoldeFraisExpire > 0)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">Le solde de frais/unité expirés ne correspond pas à la dernière opération d''expiration. Transférez ce cas au TI.</font>'
		set @Proceder = 0
		END

	IF @DemandeDeProceder = 0 
		AND @Proceder = 1
		AND EXISTS (SELECT 1 FROM #FraisDispo WHERE SoldeUniteExpire > 0 AND SoldeFraisExpire > 0 )
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  'Solde de frais expirés pouvant être remis disponibles : <font color="green">' + CAST( (SELECT SoldeFraisExpire = SUM(SoldeFraisExpire) FROM #FraisDispo) as VARCHAR) + ' $</font>.  Cochez "True" pour procéder.'
		--set @Proceder = 0
		END

	IF @DemandeDeProceder = 1 AND @Proceder = 1

		BEGIN

		DECLARE 
			@OperID INT,
			@OperDate DATETIME = GETDATE(),
			@ConventionID INT,
			@ConventionOperAmount MONEY,
			@UnitReductionID INT,
			@fUnitQtyUse FLOAT,
			@OtherAccountOperAmount MONEY,
			@NewOperID INT	


		DECLARE MyCursor CURSOR FOR

			SELECT DernierOperIDExpire FROM #FraisDispo WHERE SoldeFraisExpire > 0

		OPEN MyCursor
		FETCH NEXT FROM MyCursor INTO @OperID

		WHILE @@FETCH_STATUS = 0
		BEGIN
	
			SELECT	
				@ConventionID = ConventionID, 
				@ConventionOperAmount = ConventionOperAmount * -1,
				@UnitReductionID = UnitReductionID,
				@fUnitQtyUse = fUnitQtyUse * -1,
				@OtherAccountOperAmount = OtherAccountOperAmount * -1
			FROM Un_Oper o
			JOIN Un_ConventionOper co on co.operid = o.operid
			JOIN Un_AvailableFeeUse af on af.operid = o.operid
			JOIN Un_OtherAccountOper oa on oa.OperID = o.OperID
			WHERE o.operid = @OperID

			INSERT INTO Un_Oper(OperTypeID, OperDate, ConnectID) 
			VALUES ('TFR', @OperDate,1)
			SELECT @NewOperID = SCOPE_IDENTITY()

			INSERT INTO Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
			VALUES (@NewOperID, @ConventionID, 'FDI', @ConventionOperAmount)

			INSERT INTO Un_AvailableFeeUse(UnitReductionID, OperID, fUnitQtyUse)
			VALUES (@UnitReductionID, @NewOperID, @fUnitQtyUse)

			INSERT INTO Un_OtherAccountOper(OperID, OtherAccountOperAmount)
			VALUES (@NewOperID,@OtherAccountOperAmount)

			FETCH NEXT FROM MyCursor INTO @OperID
		END
		CLOSE MyCursor
		DEALLOCATE MyCursor

		DELETE from tblTEMP_RemettreFraisDisponible where conventionno = @ConventionNo


		IF SCOPE_IDENTITY() IS NULL 
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">Aucun Frais n''a été remis disponible.</font>'
			set @Proceder = 0
			END

		
		-- refaire le dataset suite au retour des frais disponible
		DELETE FROM #FraisDispo
		INSERT INTO #FraisDispo
		SELECT 
			Souscripteur = HS.FirstName + ' ' + HS.LastName,
			SubscriberID = C.SubscriberID,
			BeneficiaryID = C.BeneficiaryID,
			AttentionTRI = case when tri.iID_Convention_Source is not null then 1 else 0 end,
			C.ConventionNo, 
			U.UnitID,
			U.InForceDate,
			SoldeUniteDispo = ISNULL(SR.UnitQtyRes,0) - ISNULL(SU.UnitQtyUse,0),
			SoldeFraisDispo = ISNULL(FD.AvailableFeeAmount, 0),

			DernierUniteExpire = ISNULL(DernierUniteExpire,0), 
			SoldeUniteExpire = ISNULL(SoldeUniteExpire,0),  
			DernierFraisExpire = ISNULL(DernierFraisExpire,0), 
			SoldeFraisExpire = ISNULL(SoldeFraisExpire,0),

			DernierOperIDExpire = ISNULL(DernierOperIDExpire,0)

		FROM 
			Un_Convention C
			JOIN Un_Unit U on U.ConventionID = C.ConventionID
			JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
			LEFT JOIN ( 
	
					-- UNITÉS RÉSILIÉES

					SELECT 
						C.ConventionID, 
						UR.UnitID,
						UnitQtyRes = SUM(UR.UnitQty)
					FROM Un_UnitReduction UR
					JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
					WHERE C.ConventionNo = @ConventionNo
					GROUP BY C.ConventionID,UR.UnitID
					) SR ON SR.UnitID = U.UnitID--SR.ConventionID = C.ConventionID
			LEFT JOIN ( 
					-- UNITÉS UTILISÉES
						-- Les untiés résiliées qui sont utilisé dans un autre groupe d'unité sont dans Un_AvailableFeeUse.fUnitQtyUse
						-- Lors de l'expiration (4 ans) des frais dispo, les unité dispo sont inscrite comme étant utilisées dans Un_AvailableFeeUse.fUnitQtyUse
					SELECT 
						C.ConventionID, 
						U.UnitID,
						UnitQtyUse = SUM(A.fUnitQtyUse)
					FROM Un_UnitReduction UR
					JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
					JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID			
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
					WHERE C.ConventionNo = @ConventionNo
					GROUP BY C.ConventionID,U.UnitID
					) SU ON SU.UnitID = U.UnitID--SU.ConventionID = C.ConventionID

			LEFT JOIN (
					-- FRAIS DISPONIBLE

					-- lors de la résil :					il y a un Oper TFR qui AJOUTE un montant de frais dispo (FDI) POSITIF (LES FRAIS DEVIENNENT DISPO)
					-- apres 4 ans lors de l'expiration :	il y a un Oper TFR qui RETIRE un montant de frais dispo (FDI) NEGATIF (LES FRAIS NE SONT PLUS DISPO)

					SELECT
						CO.ConventionID,
						UnitID = ISNULL(UR.UnitID,CT.UnitID),
						AvailableFeeAmount =SUM( CO.ConventionOperAmount)
					FROM Un_ConventionOper CO
					JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
					JOIN Un_Oper o on co.OperID = o.OperID

					-- Le UnitID lors de la résil
					LEFT JOIN Un_Cotisation CT ON CT.OperID = O.OperID

					-- Le UnitID lors de l'expiration
					LEFT JOIN Un_AvailableFeeUse af ON af.operid = o.operid
					LEFT JOIN Un_UnitReduction UR ON UR.UnitReductionID = AF.UnitReductionID

					WHERE c.ConventionNo = @ConventionNo
						AND CO.ConventionOperTypeID = 'FDI' --Frais disponible
					GROUP BY CO.ConventionID,ISNULL(UR.UnitID,CT.UnitID)
						)FD ON FD.UnitID = U.UnitID
			LEFT JOIN (
				SELECT DISTINCT r.iID_Convention_Source
				from tblOPER_OperationsRIO r
				where r.OperTypeID = 'TRI'
				) tri on tri.iID_Convention_Source = c.ConventionID

			LEFT JOIN	(
				SELECT 
					CO.CONVENTIONID,
					UR.UnitID,
					DernierOperIDExpire = OA.OperID, 
					DernierUniteExpire = af.fUnitQtyUse, 
					S1.SoldeUniteExpire,  
					DernierFraisExpire = OA.OtherAccountOperAmount, 
					S1.SoldeFraisExpire
				FROM Un_Oper O
				JOIN Un_ConventionOper co on co.operid = o.operid
				JOIN Un_AvailableFeeUse af ON af.operid = o.operid
				JOIN Un_UnitReduction UR ON UR.UnitReductionID = AF.UnitReductionID
				JOIN Un_OtherAccountOper OA ON OA.OperID = O.OperID
				JOIN (
					select	
						C.ConventionNo,
						UR.UnitID,
						MAX_OperID = MAX(o.OperID),
						SoldeUniteExpire = SUM(AF.fUnitQtyUse),
						SoldeFraisExpire = SUM(oa.OtherAccountOperAmount)
					FROM Un_Oper o
					JOIN Un_ConventionOper co ON co.operid = o.operid
					JOIN Un_AvailableFeeUse af ON af.operid = o.operid
					JOIN Un_UnitReduction UR ON UR.UnitReductionID = AF.UnitReductionID
					JOIN Un_Convention C ON C.ConventionID = CO.ConventionID
					JOIN Un_OtherAccountOper oa ON oa.OperID = o.OperID
					WHERE  C.ConventionNo = @ConventionNo
					GROUP BY C.ConventionNo, UR.UnitID	
					) S1 ON S1.MAX_OperID = O.OperID AND S1.UnitID = UR.UnitID
				)SoldeExpir on SoldeExpir.UnitID = U.UnitID

		WHERE c.ConventionNo = @ConventionNo


		if EXISTS (select 1 from #FraisDispo where SoldeFraisExpire = 0 AND SoldeFraisDispo > 0 )	
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="green">SUCCÈS : Les frais ont été remis disponibles.</font>'
			set @Proceder = 0
			END
		ELSE
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then '<br>' ELSE '' end +  '<font color="red">UNE ERREUR EST SURVENUE. COMMUNIQUEZ AVEC LES TI.</font>'
			set @Proceder = 0
			END			
			
			

		END

		
	
	SELECT 
		*
	FROM (
		
		SELECT 
			LeMessage = @cMessage,
			Souscripteur	,
			SubscriberID	,
			BeneficiaryID	,
			AttentionTRI	,
			ConventionNo	,
			UnitID	,
			InForceDate,
			SoldeUniteDispo	,
			SoldeFraisDispo	,
			DernierUniteExpire	,
			SoldeUniteExpire	,
			DernierFraisExpire	,
			SoldeFraisExpire

		FROM #FraisDispo
		
		UNION
		
		-- Message
		SELECT 
			LeMessage = @cMessage,
			Souscripteur = NULL	,
			SubscriberID = NULL	,
			BeneficiaryID = NULL	,
			AttentionTRI = NULL	,
			ConventionNo = NULL	,
			UnitID = NULL	,
			InForceDate = NULL	,
			SoldeUniteDispo = NULL	,
			SoldeFraisDispo = NULL	,
			DernierUniteExpire = NULL	,
			SoldeUniteExpire = NULL	,
			DernierFraisExpire = NULL	,
			SoldeFraisExpire = NULL
		WHERE NOT EXISTS (SELECT 1 FROM #FraisDispo)
		) V




END


