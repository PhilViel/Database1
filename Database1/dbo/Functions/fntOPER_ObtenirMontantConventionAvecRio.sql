/****************************************************************************************************
Code de service		:		fntOPER_ObtenirMontantConventionAvecRIO
Nom du service		:		Obtenir les intérets sur les montants souscrits tenant compte des RIO   
But					:		Récupérer le montant d’intérêts sur un montant souscrit tnant compte des RIO
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                                 Obligatoir
                        ----------                  ----------------                            --------------                       
                        iIdConvention	            Identifiant unique de la convention         Oui
						dtDateDebut	                Date de début
						dtDateFin	                Date de fin
						vcCodeCategorie	            Catégorie d’opérations à renvoyer

Exemple d'appel:
                
                SELECT * FROM fntOPER_ObtenirMontantConventionAvecRIO (45212,NULL,NULL,NULL)

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        Un_ConventionOper	        ConventionOperAmount	                    Montant de l’interet
						Un_ConventionOper	        ConventionOperDate	                        Date de l’opération sur la convention
						Un_Oper	                    mFrais	                                    Frais
						Un_Oper	                    iID_Oper	                                Identifiant unique de l’opération
						Un_Oper	                    OperDate	                                Date de l’opération
						Un_Oper	                    OperTypeID	                                Type d’opération

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-12-16					Mbaye Diakhate							Création de la fonction           
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirMontantConventionAvecRio]
						( @iIdConvention INT,
						  @dtDateDebut DATETIME,
						  @dtDateFin DATETIME,
						  @vcCodeCategorie VARCHAR(100))
RETURNS  @tMontantInterets 
	TABLE ( ConventionOperAmount MONEY,
			OperDate DATETIME,
			iID_Oper INT,
			OperTypeID CHAR(3),
			ConventionOperTypeID CHAR(3),
			ConventionID INT)
BEGIN
	IF @dtDateDebut IS NULL SET @dtDateDebut = '1900/01/01'
	IF @dtDateFin IS NULL SET @dtDateFin = GETDATE()

	IF @vcCodeCategorie IS NULL
		INSERT INTO @tMontantInterets
			 SELECT ConventionOperAmount = CO.ConventionOperAmount,--Montant de l’interet
					OperDate = O.OperDate,--Date de l'operation
					iID_Oper = O.Operid,--l'id de l'operation
					OperTypeID = O.OperTypeID,--le type de l'operation
					ConventionOperTypeID = ConventionOperTypeID,
					conventionid = CO.ConventionID
			   FROM Un_ConventionOper CO
			   JOIN Un_Oper O ON O.OperID = CO.OperID
			  WHERE (O.OperDate >= @dtDateDebut AND O.OperDate <=  @dtDateFin)
				AND CO.ConventionID  = @iIdConvention 
			
			UNION ALL	 --AJOUTER LE CALCUL DES INTERETS RIO
				
				SELECT ConventionOperAmount = COP.ConventionOperAmount,--Montant de l’interet
									OperDate = O.OperDate,--Date de l'operation
									iID_Oper = O.Operid,--l'id de l'operation
									OperTypeID = O.OperTypeID,--le type de l'operation
									ConventionOperTypeID = ConventionOperTypeID,
									conventionid = COP.ConventionID
				FROM Un_ConventionOper COP 
				JOIN Un_Oper O ON COP.OperID = O.OperID AND O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
				WHERE COP.ConventionID = @iIdConvention  AND 
				COP.ConventionOperTypeID  = 'IS+' AND O.OperTypeID ='RIO'
	ELSE 
		INSERT INTO @tMontantInterets
			 SELECT ConventionOperAmount = CO.ConventionOperAmount,--Montant de l’interet
					OperDate = O.OperDate,--Date de l'operation
					iID_Oper = O.Operid,--l'id de l'operation
					OperTypeID = O.OperTypeID,--le type de l'operation
					ConventionOperTypeID = ConventionOperTypeID,
					conventionid = CO.ConventionID
			   FROM Un_ConventionOper CO
			   JOIN Un_Oper O ON O.OperID = CO.OperID
			   JOIN tblOPER_OperationsCategorie OC on OperTypeID = OC.cID_Type_Oper 
							AND ConventionOperTypeID = OC.cID_Type_Oper_Convention
			   JOIN tblOPER_CategoriesOperation COP ON COP.iID_Categorie_Oper = OC.iID_Categorie_Oper
					AND COP.vcCode_Categorie = @vcCodeCategorie 
			  WHERE (O.OperDate >= @dtDateDebut AND O.OperDate <=  @dtDateFin)
				AND CO.ConventionID  = @iIdConvention 
				
			UNION ALL	 --AJOUTER LE CALCUL DES INTERETS RIO
				
				SELECT ConventionOperAmount = COP.ConventionOperAmount,--Montant de l’interet
									OperDate = O.OperDate,--Date de l'operation
									iID_Oper = O.Operid,--l'id de l'operation
									OperTypeID = O.OperTypeID,--le type de l'operation
									ConventionOperTypeID = ConventionOperTypeID,
									conventionid = COP.ConventionID
				FROM Un_ConventionOper COP 
				JOIN Un_Oper O ON COP.OperID = O.OperID AND O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
				WHERE COP.ConventionID = @iIdConvention  AND 
				COP.ConventionOperTypeID  = 'IS+' AND O.OperTypeID ='RIO'

			UNION ALL	 --AJOUTER LE CALCUL DES INTERETS PAE Lalonde Jocelyne A.
				
				SELECT ConventionOperAmount = COP.ConventionOperAmount,--Montant de l’interet
									OperDate = O.OperDate,--Date de l'operation
									iID_Oper = O.Operid,--l'id de l'operation
									OperTypeID = O.OperTypeID,--le type de l'operation
									ConventionOperTypeID = ConventionOperTypeID,
									conventionid = COP.ConventionID
				FROM Un_ConventionOper COP 
				JOIN Un_Oper O ON COP.OperID = O.OperID AND O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
				WHERE COP.ConventionID = @iIdConvention  AND 
				COP.ConventionOperTypeID  = 'IS+' AND O.OperTypeID ='PAE'

	RETURN
END