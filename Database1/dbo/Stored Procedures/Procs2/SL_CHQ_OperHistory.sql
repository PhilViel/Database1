/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_OperHistory
Description         :	Procédure qui retournera l'historique des chèques pour une opération précise.
Valeurs de retours  :	Dataset :
				vcRefType			VARCHAR(10)		Le type d'opération qui genère le chèque.
				dtOperation			DATETIME		La date de l'opération.
				vcDescription			VARCHAR(50)		La convention qui est la source de l'opération
				dtHistory			DATETIME		La date de historique sur le chèque.
				vcStatus			VARCHAR(50)		L'état du chèque (proposé, accepté, etc.).
				iCheckNumber			INTEGER		Le numéro de chèque.
				vcReason			VARCHAR(50)		La raison de l'historique de chèque.
Note                :	ADX0000710	IA	2005-09-12	Bernie MacIntyre			Création
										2014-09-24	Donald Huppé	Modification pour les DDD : on passe le operid dans le champ iOperationID.
																	Ajout après le UNION ALL pour avoir l'info de la DDD
																	Donc, la sp retourne maintenant l'info du chèque ou de la DDD ou les 2.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_OperHistory] (
	@iOperationID INTEGER ) -- Identifiant unique de l'opération, la convention qui est la source de l'opération.
AS BEGIN

	SET NOCOUNT ON

select *
from (

	SELECT DISTINCT
		C.iCheckID, 
		O.vcRefType,
		O.dtOperation,
		O.vcDescription,
		CH.dtHistory,
		CH.iCheckHistoryID,
		CS.vcStatusDescription,
		iCheckNumber = CASE 
			WHEN CS.iCheckStatusID IN (4,5) THEN C.iCheckNumber
		ELSE NULL
		END,
		CH.vcReason
	FROM CHQ_Operation O
	JOIN Un_OperLinkToCHQOperation ON O.iOperationID = Un_OperLinkToCHQOperation.iOperationID
	join UN_OPER Op on Un_OperLinkToCHQOperation.operID = Op.OperID
	JOIN CHQ_OperationDetail OD ON O.iOperationID = OD.iOperationID
	LEFT JOIN CHQ_CheckOperationDetail COD ON OD.iOperationDetailID = COD.iOperationDetailID
	LEFT JOIN CHQ_Check C ON COD.iCheckID = C.iCheckID
	LEFT JOIN CHQ_CheckHistory CH ON C.iCheckID = CH.iCheckID
	LEFT JOIN CHQ_CheckStatus CS ON CH.iCheckStatusID = CS.iCheckStatusID
	WHERE
		--O.iOperationID = @iOperationID
		op.OperID = @iOperationID
	--ORDER BY CH.iCheckHistoryID, CH.dtHistory


	UNION all

	SELECT 

		iCheckID = ddd.id , 
		vcRefType = o.opertypeID,
		dtOperation = f.DateEtat,
		vcDescription = '',
		dtHistory = f.DateEtat,
		iCheckHistoryID = 0,
		vcStatusDescription = f.Etat,
		iCheckNumber = -1 * ddd.id, -- on multiplie par -1 uniquement pour affichier le signe "-" afin d'indiquer qu'il s'agit d'une DDD
		vcReason = '--> DDD : ' + CAST (DDD.Montant AS VARCHAR) + ' $'
 
	FROM  
		DBO.fntOPER_ObtenirEtatDDD (NULL, GETDATE()) F
		join DecaissementDepotDirect ddd on ddd.id = f.id
		join un_oper o on ddd.IdOperationFinanciere = o.OperID
	where o.OperID = @iOperationID
	) V
order by iCheckHistoryID,dtHistory

END
