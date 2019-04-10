/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_IfHavePRAOnConv
Description         :	Indique s’il y a eu un paiement de revenu accumulé sur la convention
Valeurs de retours  :	Dataset :
				OperDate	DATETIME	Date d’opération du paiement de revenu accumulé
				OperTypeID	CHAR(3)		Type d’opération
				OperTypeDesc	VARCHAR(75)	Description du type d’opération


Note                :	ADX0000992	IA	2006-05-19	Alain Quirion		Création								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_IfHavePRAOnConv] (
@ConventionID INTEGER)	--ID de la convention
AS
BEGIN
		SELECT 
			O.OperDate,
			O.OperTypeID, 
			OT.OperTypeDesc
		FROM Un_Oper O
		JOIN Un_ConventionOper CO ON O.OperID = CO.OperID	
		JOIN Un_OperType OT ON O.OperTypeID = OT.OperTypeID		
		JOIN Un_ConventionOperType CT ON CO.ConventionOperTypeID = CT.ConventionOperTypeID 
		WHERE CO.ConventionID = @ConventionID 
			AND O.OperTypeID = 'PRA'	-- AIP
		ORDER BY O.OperDate DESC
END


