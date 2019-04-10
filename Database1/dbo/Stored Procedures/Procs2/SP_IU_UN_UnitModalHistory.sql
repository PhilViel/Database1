
/****************************************************************************************************
Code de service		:		SP_IU_UN_HumanSocialNumber
Nom du service		:		SP_IU_UN_HumanSocialNumber
But					:		Création ou modification d'un historique de modalité
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@ConnectID MoID,			-- Identificateur de la connection de l'usager
						@UnitModalHistoryID MoID,	-- Identificateur unique
						@UnitID MoID,				-- Identificateur unique du groupe d'unités auquel appartient l'historique
						@ModalID MoID,				-- Identificateur unique de la modalité de l'historique
						@StartDate MoGetDate )		-- Date d'entrée en vigueur de la modalité

Exemple d'appel:
					
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O																		>0  :	Tout à fonctionné (HumanSocialNumberID du nouvel enregistrement
                     																			<=0 :	Erreur SQL
                    
Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2005-02-03					Bruno Lapointe							Création							ADX0000492	IA	
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()

 ****************************************************************************************************/

CREATE PROCEDURE dbo.SP_IU_UN_UnitModalHistory (
	@ConnectID MoID, -- Identificateur de la connection de l'usager
	@UnitModalHistoryID MoID, -- Identificateur unique
	@UnitID MoID, -- Identificateur unique du groupe d'unités auquel appartient l'historique
	@ModalID MoID, -- Identificateur unique de la modalité de l'historique
	@StartDate MoGetDate ) -- Date d'entrée en vigueur de la modalité
AS
BEGIN
	DECLARE
		@IResultID MoID

	IF @UnitModalHistoryID = 0
	BEGIN
		INSERT INTO Un_UnitModalHistory (
			UnitID,
			ModalID,
			ConnectID,
			StartDate )
		VALUES (
			@UnitID,
			@ModalID,
			@ConnectID,
			@StartDate )

		IF @@ERROR = 0
			SELECT @IResultID = SCOPE_IDENTITY()
		ELSE
			SET @IResultID = 0
	END
	ELSE
	BEGIN
		UPDATE Un_UnitModalHistory
		SET
			UnitID = @UnitID,
			ModalID = @ModalID,
			StartDate = @StartDate
		WHERE UnitModalHistoryID = @UnitModalHistoryID

		IF @@ERROR = 0
			SET @IResultID = @UnitModalHistoryID
		ELSE
			SET @IResultID = 0
	END

	-- S'assure que la plus récente modalité de l'historique soit sur le groupe d'unité
	IF @IResultID > 0
	BEGIN
		UPDATE dbo.Un_Unit 
		SET
			ModalID = MH.ModalID
		FROM dbo.Un_Unit 
		JOIN (
			SELECT
				UnitID,
				StartDate = MAX(StartDate)
			FROM Un_UnitModalHistory
			WHERE UnitID = @UnitID
			GROUP BY UnitID
			) V ON V.UnitID = Un_Unit.UnitID
		JOIN Un_UnitModalHistory MH ON MH.UnitID = Un_Unit.UnitID AND MH.StartDate = V.StartDate 

		IF @@ERROR <> 0
			SET @IResultID = 0
	END

	RETURN @IResultID
END


