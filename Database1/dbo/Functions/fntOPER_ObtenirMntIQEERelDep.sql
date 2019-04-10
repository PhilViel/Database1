/****************************************************************************************************
Code de service		:		fntOPER_ObtenirMntIQEERelDep
Nom du service		:		Obtenir les montants d'IQÉÉ 
But					:		Récupérer le solde d’IQÉÉ et d’intérêts IQÉÉ à une date donnée.
Facette				:		IQEE

Parametres d'entrée :	Parametres					Description                             Obligatoire
                        ----------                  ----------------                        --------------                       
                        @iIdConvention	            Identifiant unique de la convention		Oui
                        @dtDateDebutReleve			Date de début du relevé					Non	(Défaut = 1900-01-01)
						@dtDateFinReleve			Date de fin du relevé de dépôt			Non (Défaut = date du jour)

Exemple d'appel:        
						SELECT * FROM fntOPER_ObtenirMntIQEERelDep(349129, '2010-01-01', '2010-12-31')
						

Parametres de sortie :  Table						Champs							Description
					    -----------------			---------------------------		--------------------------
                        N/A							mMntIQEE						Montant IQEE
													mMntIntIQEE						Montant d'intérêts IQEE
													mMntIQEEMaj						Montant d'IQEE majoré
													mMntIQEECdb						Montant du crédit de base de l'IQEE
													iIDConvention					Identitifiant de la convention
                        
Historique des modifications :
						Date		Programmeur								Description
						----------	-------------------------------------	-------------------------------------------------
						2010-02-05	Jean-François Gauthier					Création de la fonction
																			
						2010-03-01	Jean-François Gauthier					Élimination de la section calculant les montants déjà payés 
																			par chèque
																			Ajout des ISNULL pour toujours retourner des valeurs avec 0 
																			s'il y a lieu
						2011-02-25	Jean-François Gauthier					Ajout de l'OperType = 'IQE'
						2011-02-28	Jean-François Gauthier					Ajout des champs mMntIQEEPae et mMntIntIQEEPae en retour
						2011-03-02	Jean-François Gauthier					Modification afin que le montant mMntIntIQEE soit pour tous les OperType liés à l'IQEE
																			sauf le 'PAE'
						2012-01-24  Mbaye Diakhate							Modification sur le calcul de mMntIQEEPae et mMntIntIQEEPae
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirMntIQEERelDep]
(	
    @iIdConvention		INT
	,@dtDateDebutReleve	DATETIME
	,@dtDateFinReleve	DATETIME
)
RETURNS  @tIQEE TABLE
(
	mMntIQEE		MONEY
	,mMntIntIQEE	MONEY
	,mMntIQEEMaj	MONEY
	,mMntIQEECdb	MONEY
	,mMntIQEEPae	MONEY
	,mMntIntIQEEPae MONEY
	,iIDConvention	INT
	,OperTypeID     CHAR(3)
)
BEGIN
	DECLARE @mMntIQEE					MONEY
			,@mMntIntIQEE				MONEY
			,@mMntIQEEMaj				MONEY
			,@mMntIQEECdb				MONEY
			,@mMntIQEEPae				MONEY
			,@mMntIntIQEEPae			MONEY

	INSERT INTO @tIQEE
	(
		mMntIQEE
		,mMntIntIQEE
		,mMntIQEEMaj	
		,mMntIQEECdb
		,mMntIQEEPae
		,mMntIntIQEEPae
		,iIDConvention
	
	)
	SELECT
		ISNULL(SUM(tmp.mMntIQEE),0)
		,ISNULL(SUM(tmp.mMntIntIQEE),0)	
		,ISNULL(SUM(tmp.mMntIQEEMaj),0)	
		,ISNULL(SUM(tmp.mMntIQEECdb),0)	
		,mMntIQEEPae	=	 (
									SELECT	
										mIQEEPAE = SUM(CO.ConventionOperAmount)
									FROM 
										dbo.Un_ConventionOper CO
										INNER JOIN dbo.Un_Oper O 
											ON O.OperID=CO.OperID AND O.OperDate BETWEEN ISNULL(@dtDateDebutReleve,'1900-01-01') AND ISNULL(@dtDateFinReleve, GETDATE())
									WHERE 
										CO.ConventionID = @iIdConvention 
										AND
										O.OperTypeID = 'PAE'
										AND
										co.ConventionOperTypeId IN (
																	SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE')
																	UNION
																	SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE')
																	UNION
																	SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION')
																	)
								--Mbaye Diakhate: enlevé le group by car il retourne plusieur ligne et cela bloque le traitement batch cas  Kezerli, vorinique
									--GROUP BY 
									--	CO.ConventionID,
									--	O.OperTypeID, 
									--	CO.OperID,
									--	O.OperDate
								 )
		,mMntIntIQEEPae	=		(
									SELECT	
										mIQEEPAE = SUM(CO.ConventionOperAmount)
									FROM 
										dbo.Un_ConventionOper CO
										INNER JOIN dbo.Un_Oper O 
											ON O.OperID=CO.OperID AND O.OperDate BETWEEN ISNULL(@dtDateDebutReleve,'1900-01-01') AND ISNULL(@dtDateFinReleve, GETDATE())
									WHERE 
										CO.ConventionID = @iIdConvention 
										AND
										O.OperTypeID = 'PAE'
										AND
										co.ConventionOperTypeId IN (SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE'))
									--Mbaye Diakhate: enlevé le group by car il retourne plusieur ligne et cela bloque le traitement batch cas  Kezerli, vorinique
									--GROUP BY 
									--	CO.ConventionID,
									--	O.OperTypeID, 
									--	CO.OperID,
									--	O.OperDate
								 )
		,@iIdConvention
		
	FROM
		(
		SELECT 
			mMntIQEE		=	 (
									CASE	WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_IQEE') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount
											ELSE		0
									END)
			,mMntIntIQEE	=	 (
									CASE	WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount
											ELSE		0
									END)
			,mMntIQEEMaj	=	 (
									CASE	WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount
											ELSE		0
									END)
			,mMntIQEECdb	=	 (
									CASE	WHEN EXISTS(SELECT 1 FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE') f WHERE f.cID_Type_Oper_Convention = co.ConventionOperTypeID) THEN co.ConventionOperAmount
											ELSE		0
									END)
			
		FROM 
			dbo.Un_ConventionOPER co
			INNER JOIN dbo.Un_OPER o
				ON co.OperID = o.OperID
		WHERE 
			 co.ConventionID = @iIdConvention
			 AND
			 o.OperDate BETWEEN ISNULL(@dtDateDebutReleve,'1900-01-01') AND ISNULL(@dtDateFinReleve, GETDATE())
			 AND
			 o.OperTypeID <> 'PAE'	-- 2011-03-02 : JFG : Au lieu de prendre IQE, on prend tout ce qui n'est pas PAE 
			 
		) AS tmp
	RETURN
END