/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_Modal_IU
Description         :	Validation avant insertion d'une modalité de dépôt
Valeurs de retours  :	Dataset :
							Code	CHAR(5)	Code d’erreur
						Validation :
							Code	Description
							MOD01	La modalité de dépôt est utilisée par des groupes d’unités, aucune modification majeure n’est permise.
							MOD02	Ce changement dans la prime d'assurance affectera les prochains dépôts des groupes d’unités utilisant cette modalité.
							MOD03	Ce changement dans la prime d'assurance affectera le calcul des bonis d’affaires des groupes d’unités utilisant cette modalité. 
							MOD04	Ce changement affectera le calcul des bonis d’affaires des groupes d’unités utilisant cette modalité. 

Note                :			ADX0001317	IA	2007-05-01	Alain Quirion	Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Modal_IU] (	
		@ModalID INTEGER,				--	ID de la modalité de dépôts
		@PlanID INTEGER,				--	ID du régime
		@ModalDate DATETIME,			--	Date d’entrée en vigueur de la modalité de dépôts.
		@PmtByYearID SMALLINT,			--	Nombre de dépôts par année.
		@PmtQty	INTEGER,				--	Nombre total de dépôt.
		@BenefAgeOnBegining INTEGER,	--	Age du bénéficiaire à la d’entrée en vigueur.
		@PmtRate MONEY,					--	Montant d’épargne et de frais par dépôt par unité.
		@SubscriberInsuranceRate MONEY,	--	Montant d’assurance souscripteur par dépôt par unité.
		@FeeByUnit MONEY,				--	Frais par unité.
		@FeeSplitByUnit MONEY,			--	Montant de frais à atteindre avant la répartition 50/50.
		@BusinessBonusToPay	BIT)		--	Indique s’il faut payer des bonis d’affaires pour les groupes d’unités de cette modalité de dépôts.
AS
BEGIN
	DECLARE @tError TABLE(
		Code CHAR(5))

	IF EXISTS ( SELECT *
				FROM dbo.Un_Unit U
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				WHERE M.ModalID = @ModalID
						AND (M.PmtByYearID <> @PmtByYearID 
							OR M.FeeSplitByUnit <> @FeeSplitByUnit 
							OR M.PmtQty <> @PmtQty 
							OR M.BenefAgeOnBegining <> @BenefAgeOnBegining 
							OR M.PmtRate <> @PmtRate
							OR M.FeeByUnit <> @FeeByUnit))
		INSERT INTO @tError
		VALUES('MOD01')

	IF EXISTS (	SELECT *
				FROM dbo.Un_Unit U
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				WHERE M.ModalID = @ModalID
						AND M.SubscriberInsuranceRate <> @SubscriberInsuranceRate)
	BEGIN
		INSERT INTO @tError
		VALUES('MOD02')

		IF @BusinessBonusToPay = 1
			INSERT INTO @tError
			VALUES('MOD03')
	END

	IF EXISTS (	SELECT *
				FROM dbo.Un_Unit U
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				WHERE M.ModalID = @ModalID
						AND M.BusinessBonusToPay <> @BusinessBonusToPay)
		INSERT INTO @tError
		VALUES('MOD04')

	SELECT Code
	FROM @tError
END


